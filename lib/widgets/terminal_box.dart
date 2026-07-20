import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/fonts.dart';

/// Monospaced auto-scrolling terminal log view.
class TerminalBox extends StatefulWidget {
  final List<String> lines;
  final double height;
  final Color color;
  final String placeholder;

  const TerminalBox({
    super.key,
    required this.lines,
    this.height = 150,
    this.color = CyberColors.neonGreen,
    this.placeholder = '// awaiting transmission...',
  });

  @override
  State<TerminalBox> createState() => _TerminalBoxState();
}

class _TerminalBoxState extends State<TerminalBox> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(TerminalBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length != oldWidget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpTo(_controller.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.color.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(10),
      child: widget.lines.isEmpty
          ? Text(
              widget.placeholder,
              style: CyberFonts.terminal(
                size: 12,
                color: widget.color.withOpacity(0.4),
              ),
            )
          : ListView.builder(
              controller: _controller,
              itemCount: widget.lines.length,
              itemExtent: 17,
              itemBuilder: (BuildContext context, int i) {
                final String line = widget.lines[i];
                final bool isErr = line.contains('ERR');
                return Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CyberFonts.terminal(
                    size: 12,
                    height: 1.1,
                    color: isErr
                        ? CyberColors.neonRed
                        : widget.color.withOpacity(0.92),
                  ),
                );
              },
            ),
    );
  }
}
