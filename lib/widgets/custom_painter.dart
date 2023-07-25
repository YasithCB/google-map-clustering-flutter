import 'package:flutter/material.dart';

class MyCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define the background color for the text
    final bgColor = Color.fromARGB(255, 0, 102, 255);

    // Draw a colored rectangle as the background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final backgroundPaint = Paint()..color = bgColor;
    canvas.drawRect(rect, backgroundPaint);

    // Draw the text
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '1 location',
      style: TextStyle(
        fontSize: size.width / 3,
        color: Colors.white,
        fontWeight: FontWeight.normal,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
