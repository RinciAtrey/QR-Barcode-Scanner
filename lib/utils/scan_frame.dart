import 'package:flutter/material.dart';

class ScanFramePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  ScanFramePainter({
    this.color = Colors.white,
    this.strokeWidth = 4,
    this.cornerLength = 30,
    this.cornerRadius = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke;

    void drawCorner(Offset origin, Offset dx, Offset dy) {
      final p = Path();
      p.moveTo(origin.dx + dx.dx * cornerRadius,
          origin.dy + dx.dy * cornerRadius);
      p.lineTo(origin.dx + dx.dx * cornerLength,
          origin.dy + dx.dy * cornerLength);
      p.moveTo(origin.dx + dy.dx * cornerRadius,
          origin.dy + dy.dy * cornerRadius);
      p.lineTo(origin.dx + dy.dx * cornerLength,
          origin.dy + dy.dy * cornerLength);
      canvas.drawPath(p, paint);
    }

    // top‑left
    drawCorner(
      Offset(0, 0),
      const Offset(1, 0),   // dx → right
      const Offset(0, 1),   // dy ↓ down
    );
    // top‑right
    drawCorner(
      Offset(size.width, 0),
      const Offset(-1, 0),  // dx ← left
      const Offset(0, 1),   // dy ↓ down
    );
    // bottom‑left
    drawCorner(
      Offset(0, size.height),
      const Offset(1, 0),   // dx → right
      const Offset(0, -1),  // dy ↑ up
    );
    // bottom‑right
    drawCorner(
      Offset(size.width, size.height),
      const Offset(-1, 0),  // dx ← left
      const Offset(0, -1),  // dy ↑ up
    );
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter old) {
    return old.color       != color ||
        old.strokeWidth != strokeWidth ||
        old.cornerLength != cornerLength;
  }
}

class ScanFrameOverlay extends StatelessWidget {
  final double size;
  const ScanFrameOverlay({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ScanFramePainter(),
      ),
    );
  }
}
