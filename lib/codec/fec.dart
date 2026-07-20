import 'dart:math' as math;
import 'dart:typed_data';

class RsException implements Exception {
  final String message;
  const RsException(this.message);
  @override
  String toString() => 'RsException: $message';
}

class RsResult {
  final Uint8List data;
  final int corrected;
  const RsResult(this.data, this.corrected);
}

/// Reed-Solomon codec over GF(2^8) with primitive polynomial 0x11D and
/// generator roots a^0 .. a^(nsym-1). A (255, 223) code with the default
/// 32 parity bytes corrects up to 16 byte errors per block; beyond that it
/// fails loudly by throwing [RsException] instead of corrupting data.
class ReedSolomon {
  ReedSolomon(this.nsym) {
    _ensureTables();
    _gen = _generatorPoly(nsym);
  }

  final int nsym;
  late final List<int> _gen;

  // ---------------------------------------------------------------- GF(256)
  static final List<int> _exp = List<int>.filled(512, 0);
  static final List<int> _log = List<int>.filled(256, 0);
  static bool _ready = false;

  static void _ensureTables() {
    if (_ready) return;
    var x = 1;
    for (var i = 0; i < 255; i++) {
      _exp[i] = x;
      _log[x] = i;
      x <<= 1;
      if (x & 0x100 != 0) x ^= 0x11D;
    }
    for (var i = 255; i < 512; i++) {
      _exp[i] = _exp[i - 255];
    }
    _ready = true;
  }

  int _mul(int x, int y) => (x == 0 || y == 0) ? 0 : _exp[_log[x] + _log[y]];

  int _div(int x, int y) {
    if (y == 0) throw const RsException('GF division by zero');
    return x == 0 ? 0 : _exp[(_log[x] - _log[y]) % 255];
  }

  int _pow(int x, int p) => x == 0 ? 0 : _exp[(_log[x] * p) % 255];

  int _inv(int x) => _exp[255 - _log[x]];

  // ------------------------------------------------------- polynomials
  // Polynomials are stored highest-degree-first: [a, b, c] = a*x^2+b*x+c.

  List<int> _polyScale(List<int> p, int x) => <int>[
    for (final int c in p) _mul(c, x),
  ];

  List<int> _polyAdd(List<int> p, List<int> q) {
    final List<int> r = List<int>.filled(math.max(p.length, q.length), 0);
    for (var i = 0; i < p.length; i++) {
      r[i + r.length - p.length] ^= p[i];
    }
    for (var i = 0; i < q.length; i++) {
      r[i + r.length - q.length] ^= q[i];
    }
    return r;
  }

  List<int> _polyMul(List<int> p, List<int> q) {
    final List<int> r = List<int>.filled(p.length + q.length - 1, 0);
    for (var j = 0; j < q.length; j++) {
      for (var i = 0; i < p.length; i++) {
        r[i + j] ^= _mul(p[i], q[j]);
      }
    }
    return r;
  }

  int _polyEval(List<int> p, int x) {
    var y = p[0];
    for (var i = 1; i < p.length; i++) {
      y = _mul(y, x) ^ p[i];
    }
    return y;
  }

  List<int> _generatorPoly(int count) {
    var g = <int>[1];
    for (var i = 0; i < count; i++) {
      g = _polyMul(g, <int>[1, _exp[i]]);
    }
    return g;
  }

  // ------------------------------------------------------------ encoding
  /// Returns `msg` followed by [nsym] parity bytes.
  List<int> encode(List<int> msg) {
    final List<int> out = <int>[...msg, ...List<int>.filled(nsym, 0)];
    for (var i = 0; i < msg.length; i++) {
      final int coef = out[i];
      if (coef != 0) {
        for (var j = 0; j < _gen.length; j++) {
          out[i + j] ^= _mul(_gen[j], coef);
        }
      }
    }
    return <int>[...msg, ...out.sublist(msg.length)];
  }

  // ------------------------------------------------------------ decoding
  List<int> _syndromes(List<int> msg) => <int>[
    0,
    for (var i = 0; i < nsym; i++) _polyEval(msg, _exp[i]),
  ];

  List<int> _errorLocator(List<int> synd) {
    // Berlekamp-Massey; `synd` carries the leading 0 placeholder.
    var errLoc = <int>[1];
    var oldLoc = <int>[1];
    for (var i = 0; i < nsym; i++) {
      var delta = synd[i + 1];
      for (var j = 1; j < errLoc.length; j++) {
        delta ^= _mul(errLoc[errLoc.length - 1 - j], synd[i + 1 - j]);
      }
      oldLoc = <int>[...oldLoc, 0];
      if (delta != 0) {
        if (oldLoc.length > errLoc.length) {
          final List<int> newLoc = _polyScale(oldLoc, delta);
          oldLoc = _polyScale(errLoc, _inv(delta));
          errLoc = newLoc;
        }
        errLoc = _polyAdd(errLoc, _polyScale(oldLoc, delta));
      }
    }
    while (errLoc.isNotEmpty && errLoc.first == 0) {
      errLoc = errLoc.sublist(1);
    }
    final int errs = errLoc.length - 1;
    if (errs * 2 > nsym) {
      throw const RsException('too many errors to correct');
    }
    return errLoc;
  }

  List<int> _findErrors(List<int> errLoc, int nmess) {
    // Chien search: a root at x = a^-(n-1-i) means an error at index i.
    final List<int> errPos = <int>[];
    for (var i = 0; i < nmess; i++) {
      if (_polyEval(errLoc, _exp[(255 - (nmess - 1 - i)) % 255]) == 0) {
        errPos.add(i);
      }
    }
    if (errPos.length != errLoc.length - 1) {
      throw const RsException('could not locate all errors');
    }
    return errPos;
  }

  List<int> _magnitudes(
    List<int> synd,
    List<int> errLoc,
    List<int> errPos,
    int nmess,
  ) {
    // Forney: e = X * Omega(X^-1) / Lambda'(X^-1), X = a^(n-1-pos).
    final int v = errLoc.length - 1;
    final List<int> sPoly = synd.reversed.toList();
    final List<int> prod = _polyMul(sPoly, errLoc);
    final List<int> omega = prod.sublist(prod.length - nsym);
    final List<int> mags = <int>[];
    for (final int p in errPos) {
      final int c = nmess - 1 - p;
      final int x = _exp[c % 255];
      final int xi = _inv(x);
      final int num = _mul(x, _polyEval(omega, xi));
      var den = 0;
      for (var j = 1; j <= v; j++) {
        if (j.isOdd) {
          den ^= _mul(errLoc[v - j], _pow(xi, j - 1));
        }
      }
      if (den == 0) {
        throw const RsException('Forney denominator is zero');
      }
      mags.add(_div(num, den));
    }
    return mags;
  }

  /// Corrects `msgIn` (data + parity) and returns the plain data.
  RsResult decode(List<int> msgIn) {
    final List<int> msg = List<int>.from(msgIn);
    final List<int> syndFull = _syndromes(msg);
    if (syndFull.reduce(math.max) == 0) {
      return RsResult(Uint8List.fromList(msg.sublist(0, msg.length - nsym)), 0);
    }
    final List<int> synd = syndFull.sublist(1);
    final List<int> errLoc = _errorLocator(syndFull);
    final List<int> errPos = _findErrors(errLoc, msg.length);
    final List<int> mags = _magnitudes(synd, errLoc, errPos, msg.length);
    for (var k = 0; k < errPos.length; k++) {
      msg[errPos[k]] ^= mags[k];
    }
    if (_syndromes(msg).reduce(math.max) != 0) {
      throw const RsException('error correction failed');
    }
    return RsResult(
      Uint8List.fromList(msg.sublist(0, msg.length - nsym)),
      errPos.length,
    );
  }

  // ------------------------------------------------------- block helpers
  static const int defaultNsym = 32;
  static const int defaultChunk = 223; // 255 - 32

  /// Splits [data] into chunks of [chunk] bytes and RS-encodes each one.
  static Uint8List encodeBlocks(
    List<int> data, {
    int nsym = defaultNsym,
    int chunk = defaultChunk,
  }) {
    final ReedSolomon rs = ReedSolomon(nsym);
    final List<int> out = <int>[];
    for (var off = 0; off < data.length; off += chunk) {
      final int end = math.min(off + chunk, data.length);
      out.addAll(rs.encode(data.sublist(off, end)));
    }
    return Uint8List.fromList(out);
  }

  /// Inverse of [encodeBlocks]: full 255-byte blocks first, then one
  /// final shorter block.
  static RsResult decodeBlocks(
    List<int> data, {
    int nsym = defaultNsym,
    int chunk = defaultChunk,
  }) {
    final ReedSolomon rs = ReedSolomon(nsym);
    final List<int> out = <int>[];
    var off = 0;
    var corrected = 0;
    while (data.length - off > 255) {
      final RsResult r = rs.decode(data.sublist(off, off + 255));
      out.addAll(r.data);
      corrected += r.corrected;
      off += 255;
    }
    if (data.length - off <= nsym) {
      throw const RsException('FEC block too short');
    }
    final RsResult r = rs.decode(data.sublist(off));
    out.addAll(r.data);
    corrected += r.corrected;
    return RsResult(Uint8List.fromList(out), corrected);
  }
}
