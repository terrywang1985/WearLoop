import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            painter: _HangerSymbolPainter(
              Theme.of(context).colorScheme.onPrimary,
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF496650)
                  : const Color(0xFFC9D5A9),
              primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'WearLoop',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontFamilyFallback: const ['serif'],
            fontSize: compact ? 23 : 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.9,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// The same hanger-and-leaf geometry as web/icons/wearloop.svg.
class _HangerSymbolPainter extends CustomPainter {
  const _HangerSymbolPainter(this.foreground, this.leaf, this.background);
  final Color foreground;
  final Color leaf;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final hanger = Path()
      ..moveTo(28, 23)
      ..cubicTo(28, 16, 39, 15, 39, 22)
      ..cubicTo(39, 26, 32, 28, 32, 32)
      ..lineTo(49, 42)
      ..cubicTo(51, 43, 50, 46, 48, 46)
      ..lineTo(16, 46)
      ..cubicTo(14, 46, 13, 43, 15, 42)
      ..lineTo(27, 35);
    canvas.drawPath(
      hanger,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final leafPath = Path()
      ..moveTo(44, 15)
      ..cubicTo(52, 14, 55, 19, 52, 25)
      ..cubicTo(45, 26, 41, 22, 44, 15)
      ..close();
    canvas.drawPath(leafPath, Paint()..color = leaf);
    canvas.drawLine(
      const Offset(45, 23),
      const Offset(50, 18),
      Paint()
        ..color = background
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HangerSymbolPainter oldDelegate) =>
      foreground != oldDelegate.foreground ||
      leaf != oldDelegate.leaf ||
      background != oldDelegate.background;
}
