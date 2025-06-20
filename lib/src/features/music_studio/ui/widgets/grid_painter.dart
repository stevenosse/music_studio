import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double keyHeight;
  final double cellWidth;
  final int totalKeys;
  final int beatsVisible;
  final ThemeData theme;

  GridPainter({
    required this.keyHeight,
    required this.cellWidth,
    required this.totalKeys,
    required this.beatsVisible,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final strongLinePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final barLinePaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines (piano keys)
    for (int i = 0; i <= totalKeys; i++) {
      final y = i * keyHeight;
      final isOctaveStart = _isOctaveStart(totalKeys - i);
      
      if (isOctaveStart) {
        strongLinePaint.color = theme.colorScheme.outline.withValues(alpha: 0.6);
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          strongLinePaint,
        );
      } else {
        paint.color = theme.colorScheme.outline.withValues(alpha: 0.2);
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          paint,
        );
      }
    }

    // Draw vertical lines (beats)
    final totalBeats = (size.width / cellWidth).ceil();
    for (int i = 0; i <= totalBeats; i++) {
      final x = i * cellWidth;
      
      if (i % 16 == 0) {
        // Bar lines (every 4 beats)
        barLinePaint.color = theme.colorScheme.outline.withValues(alpha: 0.8);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          barLinePaint,
        );
      } else if (i % 4 == 0) {
        // Beat lines
        strongLinePaint.color = theme.colorScheme.outline.withValues(alpha: 0.4);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          strongLinePaint,
        );
      } else {
        // Sub-beat lines
        paint.color = theme.colorScheme.outline.withValues(alpha: 0.15);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          paint,
        );
      }
    }

    // Draw alternating row backgrounds for better visibility
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < totalKeys; i++) {
      final midiNote = 21 + (totalKeys - 1 - i); // A0 = 21
      final isBlackKey = _isBlackKey(midiNote);
      
      if (isBlackKey) {
        backgroundPaint.color = theme.colorScheme.surface.withValues(alpha: 0.05);
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            i * keyHeight,
            size.width,
            keyHeight,
          ),
          backgroundPaint,
        );
      }
    }
  }

  bool _isOctaveStart(int keyIndex) {
    if (keyIndex <= 0) return false;
    final midiNote = 21 + keyIndex - 1; // A0 = 21
    return midiNote % 12 == 0; // C notes
  }

  bool _isBlackKey(int midiNote) {
    final noteInOctave = midiNote % 12;
    // Black keys: C#, D#, F#, G#, A# (1, 3, 6, 8, 10)
    return [1, 3, 6, 8, 10].contains(noteInOctave);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return keyHeight != oldDelegate.keyHeight ||
           cellWidth != oldDelegate.cellWidth ||
           totalKeys != oldDelegate.totalKeys ||
           beatsVisible != oldDelegate.beatsVisible;
  }
}