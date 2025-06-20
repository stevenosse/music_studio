import 'package:flutter/material.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_notifier.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/dimens.dart';
import '../../../models/note.dart';

class PianoRollVelocityEditorWidget extends StatefulWidget {
  final List<Note> notes;
  final double cellWidth;
  final int totalSteps;
  final Function(Note, int) onVelocityChanged;

  const PianoRollVelocityEditorWidget({
    super.key,
    required this.notes,
    required this.cellWidth,
    required this.totalSteps,
    required this.onVelocityChanged,
  });

  @override
  State<PianoRollVelocityEditorWidget> createState() =>
      _PianoRollVelocityEditorWidgetState();
}

class _PianoRollVelocityEditorWidgetState
    extends State<PianoRollVelocityEditorWidget> {
  Note? _draggingNote;
  int? _initialVelocity;

  @override
  Widget build(BuildContext context) {
    return _buildVelocityBars(context);
  }

  Widget _buildVelocityBars(BuildContext context) {
    final theme = Theme.of(context);
    final totalWidth = widget.totalSteps * widget.cellWidth;

    return Consumer<PianoRollNotifier>(
      builder: (context, notifier, child) {
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SizedBox(
            width: totalWidth,
            height: Dimens.pianoRollVelocityBarHeight,
            child: CustomPaint(
              painter: _VelocityBarsPainter(
                notes: widget.notes,
                selectedNotes: notifier.value.selectedNotes,
                cellWidth: widget.cellWidth,
                totalSteps: widget.totalSteps,
                theme: theme,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details) {
    final note = _findNoteAtPosition(details.localPosition);
    if (note != null) {
      setState(() {
        _draggingNote = note;
        _initialVelocity = note.velocity;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggingNote == null || _initialVelocity == null) return;

    final barHeight =
        Dimens.pianoRollVelocityBarHeight - 20; // Account for padding
    final relativeY = details.localPosition.dy - 10; // Account for top padding
    final velocityRatio = 1.0 - (relativeY / barHeight).clamp(0.0, 1.0);
    final newVelocity = (velocityRatio * 127).round().clamp(1, 127);

    widget.onVelocityChanged(_draggingNote!, newVelocity);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _draggingNote = null;
      _initialVelocity = null;
    });
  }

  Note? _findNoteAtPosition(Offset position) {
    final x = position.dx;

    for (final note in widget.notes) {
      final noteStartX = note.step.toDouble() * widget.cellWidth;
      final noteEndX = noteStartX + (note.duration * widget.cellWidth);

      if (x >= noteStartX && x <= noteEndX) {
        return note;
      }
    }

    return null;
  }
}

class _VelocityBarsPainter extends CustomPainter {
  final List<Note> notes;
  final Set<String> selectedNotes;
  final double cellWidth;
  final int totalSteps;
  final ThemeData theme;

  _VelocityBarsPainter({
    required this.notes,
    required this.selectedNotes,
    required this.cellWidth,
    required this.totalSteps,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGridLines(canvas, size);
    _drawVelocityBars(canvas, size);
    _drawVelocityLabels(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.surface
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Horizontal lines (velocity levels)
    for (int i = 0; i <= 4; i++) {
      final y = (size.height - 20) * i / 4 + 10;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Vertical lines (time grid)
    for (int step = 0; step <= totalSteps; step += 4) {
      final x = step * cellWidth;
      canvas.drawLine(
        Offset(x, 10),
        Offset(x, size.height - 10),
        paint,
      );
    }
  }

  void _drawVelocityBars(Canvas canvas, Size size) {
    final barHeight = size.height - 20; // Account for padding

    for (final note in notes) {
      final isSelected = selectedNotes.contains(note.id);
      final noteStartX = note.step.toDouble() * cellWidth;
      final noteWidth = note.duration * cellWidth;
      final velocityRatio = note.velocity / 127.0;
      final barHeightForNote = barHeight * velocityRatio;

      final paint = Paint()
        ..color = isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.8)
            : theme.colorScheme.secondary.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(
        noteStartX + 1,
        size.height - 10 - barHeightForNote,
        noteWidth - 2,
        barHeightForNote,
      );

      canvas.drawRect(rect, paint);

      // Border
      final borderPaint = Paint()
        ..color =
            isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawVelocityLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final velocityLevels = [127, 96, 64, 32, 1];

    for (int i = 0; i < velocityLevels.length; i++) {
      final velocity = velocityLevels[i];
      final y = (size.height - 20) * i / 4 + 10;

      textPainter.text = TextSpan(
        text: velocity.toString(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 9,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(4, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VelocityBarsPainter oldDelegate) {
    return oldDelegate.notes != notes ||
        oldDelegate.selectedNotes != selectedNotes ||
        oldDelegate.cellWidth != cellWidth;
  }
}