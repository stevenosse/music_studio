import 'package:flutter/material.dart';
import '../../../../../core/theme/dimens.dart';
import '../../../models/note.dart';

class PianoRollNoteWidget extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onDelete;
  final double cellWidth;
  final Function(bool, Offset) onResizeStart;
  final Function(Offset) onResizeUpdate;
  final VoidCallback onResizeEnd;

  const PianoRollNoteWidget({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onDelete,
    required this.cellWidth,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
  });

  @override
  State<PianoRollNoteWidget> createState() => _PianoRollNoteWidgetState();
}

class _PianoRollNoteWidgetState extends State<PianoRollNoteWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteColor = _getNoteColor(theme);
    final borderColor = _getBorderColor(theme);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onSecondaryTap: widget.onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: noteColor,
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _isHovering || widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.note.color.withAlpha(51), // ~20% opacity
                      blurRadius: widget.isSelected ? 6 : 3,
                      offset: Offset(0, widget.isSelected ? 3 : 1),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Note content
              _buildNoteContent(theme),
              
              // Resize handles (only when selected)
              if (widget.isSelected) ..._buildResizeHandles(theme),
              
              // Velocity indicator
              _buildVelocityIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteContent(ThemeData theme) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _getNoteLabel(widget.note.pitch),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getTextColor(),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles(ThemeData theme) {
    return [
      // Left resize handle
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: Dimens.pianoRollResizeHandleWidth,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            onPanStart: (details) => _startResize(true, details.globalPosition),
            onPanUpdate: (details) => widget.onResizeUpdate(details.globalPosition),
            onPanEnd: (details) => _endResize(),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 2,
                  height: double.infinity,
                  color: Colors.white.withAlpha(204), // ~80% opacity
                ),
              ),
            ),
          ),
        ),
      ),
      
      // Right resize handle
      Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: Dimens.pianoRollResizeHandleWidth,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            onPanStart: (details) => _startResize(false, details.globalPosition),
            onPanUpdate: (details) => widget.onResizeUpdate(details.globalPosition),
            onPanEnd: (details) => _endResize(),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 2,
                  height: double.infinity,
                  color: Colors.white.withAlpha(204), // ~80% opacity
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildVelocityIndicator() {
    final velocityHeight = (widget.note.velocity / 127.0) * 4.0;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: velocityHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(77), // ~30% opacity
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
      ),
    );
  }



  void _startResize(bool fromLeft, Offset globalPosition) {
    widget.onResizeStart(fromLeft, globalPosition);
  }

  void _endResize() {
    widget.onResizeEnd();
  }

  Color _getNoteColor(ThemeData theme) {
    if (widget.note.isMuted) {
      return widget.note.color.withAlpha(128); // 50% opacity
    }
    if (widget.isSelected) {
      return theme.colorScheme.primary.withAlpha(230); // ~90% opacity
    }
    if (_isHovering) {
      return widget.note.color.withAlpha(204); // ~80% opacity
    }
    return widget.note.color.withAlpha(178); // ~70% opacity
  }

  Color _getBorderColor(ThemeData theme) {
    if (widget.isSelected) {
      return theme.colorScheme.primary;
    }
    if (_isHovering) {
      return Colors.green.shade300;
    }
    return Colors.green.shade400;
  }

  Color _getTextColor() {
    return Colors.white;
  }

  String _getNoteLabel(int midiNote) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final noteName = noteNames[midiNote % 12];
    final octave = (midiNote / 12).floor() - 1;
    return '$noteName$octave';
  }
}