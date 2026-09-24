import 'package:flutter/material.dart';

class GraphPaperBackground extends StatelessWidget {
  final Widget child;

  const GraphPaperBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GraphPaperPainter(),
      child: child,
    );
  }
}

class GraphPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background color
    final backgroundPaint = Paint()
      ..color = const Color.fromARGB(255, 34, 29, 41);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Grid line settings
    final gridPaint = Paint()
      ..color = const Color.fromARGB(255, 179, 166, 194)
      ..strokeWidth = 0.6;

    const double gridSize = 20;

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}