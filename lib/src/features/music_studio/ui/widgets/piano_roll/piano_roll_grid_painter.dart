import 'package:flutter/material.dart';
import '../../../logic/piano_roll/piano_roll_state.dart';

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
  final SnapResolution snapResolution;

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
    required this.snapResolution,
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
    final whiteKeyPaint = Paint()..color = const Color(0xFF303030); // Slightly lighter grey
    final blackKeyPaint = Paint()..color = const Color(0xFF212121); // Darker grey

    for (int i = 0; i < totalKeys; i++) {
      final y = i * keyHeight;
      final midiNote = lowestNote + (totalKeys - 1 - i);
      final noteInOctave = midiNote % 12;
      final isBlackKey = [1, 3, 6, 8, 10].contains(noteInOctave);

      final paint = isBlackKey ? blackKeyPaint : whiteKeyPaint;
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, keyHeight),
        paint,
      );
    }
  }

  void _drawHorizontalLines(Canvas canvas, Size size) {
    final linePaint = Paint()..strokeWidth = 1.0;

    for (int i = 0; i <= totalKeys; i++) {
      final y = i * keyHeight;
      final midiNote = lowestNote + (totalKeys - 1 - i);
      final noteInOctave = midiNote % 12;
      final isOctaveStart = noteInOctave == 0;

      if (isOctaveStart) {
        linePaint.color = Colors.black.withValues(alpha: 0.35);
      } else {
        linePaint.color = Colors.black.withValues(alpha: 0.2);
      }
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawVerticalLines(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    final beatPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;
    final subdivisionPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    final stepsPerBeat = stepsPerBar / 4.0;
    final double subdivisionSize = (snapResolution.divisionsPerBar > 0)
        ? stepsPerBar / snapResolution.divisionsPerBar.toDouble()
        : 0;

    for (int i = 0; i <= totalSteps; i++) {
      final x = i * cellWidth;
      final isBarStart = i % stepsPerBar == 0;
      final isBeatStart = i % stepsPerBeat == 0;

      bool isSubdivision = false;
      if (subdivisionSize > 0) {
        // Use a small tolerance for floating point modulo operations
        isSubdivision = (i % subdivisionSize).abs() < 0.001;
      }

      if (isBarStart) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), barPaint);
      } else if (isBeatStart) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), beatPaint);
      } else if (isSubdivision) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), subdivisionPaint);
      }
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
        isLooping != oldDelegate.isLooping ||
        snapResolution != oldDelegate.snapResolution;
  }
}