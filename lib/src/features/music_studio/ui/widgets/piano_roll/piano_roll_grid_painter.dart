import 'package:flutter/material.dart';

class PianoRollGridPainter extends CustomPainter {
  final double cellWidth;
  final double keyHeight;
  final int totalSteps;
  final int totalKeys;
  final int stepsPerBar;
  final int lowestNote;
  final double playheadPosition;
  final double loopStart;
  final double loopEnd;
  final bool isLooping;

  PianoRollGridPainter({
    required this.cellWidth,
    required this.keyHeight,
    required this.totalSteps,
    required this.totalKeys,
    required this.stepsPerBar,
    required this.lowestNote,
    required this.playheadPosition,
    required this.loopStart,
    required this.loopEnd,
    required this.isLooping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawHorizontalLines(canvas, size);
    _drawVerticalLines(canvas, size);
    _drawLoopRegion(canvas, size);
    _drawPlayhead(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.grey.shade900;
    canvas.drawRect(Offset.zero & size, backgroundPaint);
  }

  void _drawHorizontalLines(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (int i = 0; i <= totalKeys; i++) {
      final y = i * keyHeight;
      
      // Determine line color based on note type
      final midiNote = lowestNote + (totalKeys - 1 - i);
      final noteInOctave = midiNote % 12;
      final isBlackKey = [1, 3, 6, 8, 10].contains(noteInOctave);
      final isOctaveStart = noteInOctave == 0; // C note
      
      // Draw background for black keys
      if (i < totalKeys && isBlackKey) {
        paint.color = Colors.black.withValues(alpha: 0.3);
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, keyHeight),
          paint,
        );
      }
      
      // Draw horizontal grid lines
      if (isOctaveStart) {
        paint.color = Colors.white.withValues(alpha: 0.4);
        paint.strokeWidth = 1.5;
      } else {
        paint.color = Colors.white.withValues(alpha: 0.15);
        paint.strokeWidth = 0.5;
      }
      
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawVerticalLines(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (int i = 0; i <= totalSteps; i++) {
      final x = i * cellWidth;
      final isBarStart = i % stepsPerBar == 0;
      final isBeatStart = i % 4 == 0; // Assuming 4 steps per beat
      
      if (isBarStart) {
        paint.color = Colors.white.withValues(alpha: 0.6);
        paint.strokeWidth = 2.0;
      } else if (isBeatStart) {
        paint.color = Colors.white.withValues(alpha: 0.4);
        paint.strokeWidth = 1.0;
      } else {
        paint.color = Colors.white.withValues(alpha: 0.2);
        paint.strokeWidth = 0.5;
      }
      
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawLoopRegion(Canvas canvas, Size size) {
    if (!isLooping) return;
    
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    final loopStartX = loopStart * cellWidth;
    final loopEndX = loopEnd * cellWidth;
    
    // Draw loop region background
    canvas.drawRect(
      Rect.fromLTWH(loopStartX, 0, loopEndX - loopStartX, size.height),
      paint,
    );
    
    // Draw loop region borders
    paint
      ..color = Colors.yellow.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(loopStartX, 0),
      Offset(loopStartX, size.height),
      paint,
    );
    
    canvas.drawLine(
      Offset(loopEndX, 0),
      Offset(loopEndX, size.height),
      paint,
    );
  }

  void _drawPlayhead(Canvas canvas, Size size) {
    final playheadX = playheadPosition * cellWidth;
    
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw playhead line
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      paint,
    );
    
    // Draw playhead triangle at top
    final trianglePath = Path()
      ..moveTo(playheadX - 6, 0)
      ..lineTo(playheadX + 6, 0)
      ..lineTo(playheadX, 12)
      ..close();
    
    paint.style = PaintingStyle.fill;
    canvas.drawPath(trianglePath, paint);
  }

  @override
  bool shouldRepaint(covariant PianoRollGridPainter oldDelegate) {
    return cellWidth != oldDelegate.cellWidth ||
        keyHeight != oldDelegate.keyHeight ||
        totalSteps != oldDelegate.totalSteps ||
        totalKeys != oldDelegate.totalKeys ||
        stepsPerBar != oldDelegate.stepsPerBar ||
        lowestNote != oldDelegate.lowestNote ||
        playheadPosition != oldDelegate.playheadPosition ||
        loopStart != oldDelegate.loopStart ||
        loopEnd != oldDelegate.loopEnd ||
        isLooping != oldDelegate.isLooping;
  }
}