import 'package:flutter/material.dart';
import 'package:mstudio/src/features/music_studio/logic/music_studio_notifier.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_notifier.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/dimens.dart';

class PianoRollHeaderWidget extends StatelessWidget {
  final ScrollController horizontalScrollController;
  final double cellWidth;
  final int totalSteps;
  final int stepsPerBar;
  final Function(double) onSeek;

  const PianoRollHeaderWidget({
    super.key,
    required this.horizontalScrollController,
    required this.cellWidth,
    required this.totalSteps,
    required this.stepsPerBar,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: Dimens.pianoRollHeaderHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left spacer (matches keyboard width)
          Container(
            width: Dimens.pianoRollKeyboardWidth,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Text(
                'Time',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ),
          
          // Time ruler
          Expanded(
            child: SingleChildScrollView(
              controller: horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: _buildTimeRuler(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRuler(BuildContext context) {
    final theme = Theme.of(context);
    final totalWidth = totalSteps * cellWidth;
    
    return Consumer2<PianoRollNotifier, MusicStudioNotifier>(
      builder: (context, pianoRollNotifier, musicStudioNotifier, child) {
        final playheadPosition = musicStudioNotifier.value.currentStep * cellWidth;
        final loopStart = pianoRollNotifier.value.loopStart;
        final loopEnd = pianoRollNotifier.value.loopEnd;
        
        return GestureDetector(
          onTapDown: (details) {
            final position = details.localPosition.dx;
            final step = position / cellWidth;
            onSeek(step);
          },
          child: SizedBox(
            width: totalWidth,
            height: Dimens.pianoRollHeaderHeight,
            child: CustomPaint(
              painter: _TimeRulerPainter(
                cellWidth: cellWidth,
                totalSteps: totalSteps,
                stepsPerBar: stepsPerBar,
                playheadPosition: playheadPosition,
                loopStart: loopStart,
                loopEnd: loopEnd,
                theme: theme,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeRulerPainter extends CustomPainter {
  final double cellWidth;
  final int totalSteps;
  final int stepsPerBar;
  final double playheadPosition;
  final double? loopStart;
  final double? loopEnd;
  final ThemeData theme;

  _TimeRulerPainter({
    required this.cellWidth,
    required this.totalSteps,
    required this.stepsPerBar,
    required this.playheadPosition,
    required this.loopStart,
    required this.loopEnd,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawLoopRegion(canvas, size);
    _drawTimeMarkers(canvas, size);
    _drawPlayhead(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.surface
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawLoopRegion(Canvas canvas, Size size) {
    if (loopStart != null && loopEnd != null) {
      final startX = loopStart! * cellWidth;
      final endX = loopEnd! * cellWidth;
      
      final paint = Paint()
        ..color = theme.colorScheme.primary.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(startX, 0, endX - startX, size.height),
        paint,
      );
      
      // Loop markers
      final markerPaint = Paint()
        ..color = theme.colorScheme.primary
        ..strokeWidth = 2;
      
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX, size.height),
        markerPaint,
      );
      
      canvas.drawLine(
        Offset(endX, 0),
        Offset(endX, size.height),
        markerPaint,
      );
    }
  }

  void _drawTimeMarkers(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int step = 0; step <= totalSteps; step++) {
      final x = step * cellWidth;
      final isBarStart = step % stepsPerBar == 0;
      final isBeatStart = step % (stepsPerBar ~/ 4) == 0;
      
      if (isBarStart) {
        // Bar line
        final paint = Paint()
          ..color = theme.dividerColor
          ..strokeWidth = 2;
        
        canvas.drawLine(
          Offset(x, size.height * 0.3),
          Offset(x, size.height),
          paint,
        );
        
        // Bar number
        final barNumber = (step ~/ stepsPerBar) + 1;
        textPainter.text = TextSpan(
          text: barNumber.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + 4, 4),
        );
      } else if (isBeatStart) {
        // Beat line
        final paint = Paint()
          ..color = theme.dividerColor.withValues(alpha: 0.7)
          ..strokeWidth = 1;
        
        canvas.drawLine(
          Offset(x, size.height * 0.5),
          Offset(x, size.height),
          paint,
        );
        
        // Beat number
        final beatInBar = ((step % stepsPerBar) ~/ (stepsPerBar ~/ 4)) + 1;
        textPainter.text = TextSpan(
          text: beatInBar.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 9,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + 2, size.height * 0.3),
        );
      } else {
        // Sub-beat line
        final paint = Paint()
          ..color = theme.dividerColor.withValues(alpha: 0.3)
          ..strokeWidth = 0.5;
        
        canvas.drawLine(
          Offset(x, size.height * 0.7),
          Offset(x, size.height),
          paint,
        );
      }
    }
  }

  void _drawPlayhead(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.error
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(playheadPosition, 0),
      Offset(playheadPosition, size.height),
      paint,
    );
    
    // Playhead triangle
    final path = Path()
      ..moveTo(playheadPosition - 6, 0)
      ..lineTo(playheadPosition + 6, 0)
      ..lineTo(playheadPosition, 12)
      ..close();
    
    final trianglePaint = Paint()
      ..color = theme.colorScheme.error
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) {
    return oldDelegate.playheadPosition != playheadPosition ||
        oldDelegate.loopStart != loopStart ||
        oldDelegate.loopEnd != loopEnd ||
        oldDelegate.cellWidth != cellWidth;
  }
}