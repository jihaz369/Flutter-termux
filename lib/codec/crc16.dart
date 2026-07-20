/// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF).
class Crc16 {
  Crc16._();

  static int compute(List<int> data, {int poly = 0x1021, int init = 0xFFFF}) {
    var crc = init;
    for (final int b in data) {
      crc ^= (b & 0xFF) << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0
            ? ((crc << 1) ^ poly) & 0xFFFF
            : (crc << 1) & 0xFFFF;
      }
    }
    return crc;
  }
}
