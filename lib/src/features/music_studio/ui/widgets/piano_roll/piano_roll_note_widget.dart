import 'package:flutter/material.dart';
import '../../../../../core/theme/dimens.dart';
import '../../../models/note.dart';

class PianoRollNoteWidget extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(Offset) onMove;
  final Function(double, bool) onResize;
  final VoidCallback onDelete;
  final double cellWidth;
  final Function(bool, Offset) onResizeStart; // Updated signature
  final VoidCallback onResizeEnd;

  const PianoRollNoteWidget({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onMove,
    required this.onResize,
    required this.onDelete,
    required this.cellWidth,
    required this.onResizeStart,
    required this.onResizeEnd,
  });

  @override
  State<PianoRollNoteWidget> createState() => _PianoRollNoteWidgetState();
}

class _PianoRollNoteWidgetState extends State<PianoRollNoteWidget> {
  bool _isHovering = false;
  bool _isResizing = false;
  bool _isMoving = false;
  Offset? _dragStartPosition;
  // int? _initialDuration; // Removed as unused
  // int? _initialStep; // Removed as unused

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteColor = _getNoteColor(theme);
    final borderColor = _getBorderColor(theme);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTap: widget.onDelete,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
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
                      color: Colors.black.withValues(alpha: 0.3),
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
            onPanStart: (details) => _startResize(true, details.globalPosition), // Pass globalPosition
            // onPanUpdate: (details) => _updateLeftResize(details), // Removed to centralize logic in grid
            onPanEnd: (details) => _endResize(),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 2,
                  height: double.infinity,
                  color: Colors.white.withValues(alpha: 0.8),
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
            onPanStart: (details) => _startResize(false, details.globalPosition), // Pass globalPosition
            // onPanUpdate: (details) => _updateRightResize(details), // Removed to centralize logic in grid
            onPanEnd: (details) => _endResize(),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 2,
                  height: double.infinity,
                  color: Colors.white.withValues(alpha: 0.8),
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
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_isResizing) return;
    
    setState(() {
      _isMoving = true;
      _dragStartPosition = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isResizing || !_isMoving || _dragStartPosition == null) return;
    
    final delta = details.localPosition - _dragStartPosition!;
    widget.onMove(delta);
    _dragStartPosition = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isResizing) return;
    
    setState(() {
      _isMoving = false;
      _dragStartPosition = null;
    });
  }

  void _startResize(bool fromLeft, Offset globalPosition) {
    setState(() {
      _isResizing = true;
    });
    widget.onResizeStart(fromLeft, globalPosition);
  }

  void _endResize() {
    setState(() {
      _isResizing = false;
    });
    widget.onResizeEnd();
  }

  Color _getNoteColor(ThemeData theme) {
    if (widget.isSelected) {
      return theme.colorScheme.primary.withValues(alpha: 0.9);
    }
    if (_isHovering) {
      return Colors.green.withValues(alpha: 0.8);
    }
    return Colors.green.withValues(alpha: 0.7);
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