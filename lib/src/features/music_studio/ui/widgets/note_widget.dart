import 'package:flutter/material.dart';
import 'package:mstudio/src/features/music_studio/models/note.dart';
import '../../../../core/theme/dimens.dart';

class NoteWidget extends StatefulWidget {
  final Note note;
  final double width;
  final double height;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(Note) onDuplicate;
  final double zoom;
  final Function(double) onResizeEnd;
  final Function(double) onResizeStart;
  final Function(Note)? onMove;
  final Function()? onRightClick;

  const NoteWidget({
    super.key,
    required this.note,
    required this.width,
    required this.height,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.zoom,
    required this.onResizeEnd,
    required this.onResizeStart,
    this.onMove,
    this.onRightClick,
  });

  @override
  State<NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  bool _isHovering = false;
  bool _isResizing = false;
  bool _isMoving = false;
  double? _initialWidth;
  int? _initialStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTap: () {
          // Right click to delete
          widget.onRightClick?.call() ?? widget.onDelete();
        },
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.9)
                : widget.color.withValues(alpha: 0.7),
            border: Border.all(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : widget.color.withValues(alpha: 0.8),
              width: widget.isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _isHovering || widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Note content
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Text(
                      _getNoteDisplayName(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTextColor(),
                        fontSize: (10 * widget.zoom).clamp(8, 12),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // Resize handles (only show when hovering or selected)
              if ((_isHovering || widget.isSelected) && widget.width > 20)
                ..._buildResizeHandles(theme),
            ],
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
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            onPanStart: (details) {
              _isResizing = true;
              _initialStep = widget.note.step;
              _initialWidth = widget.width;
            },
            onPanUpdate: (details) {
              if (_isResizing &&
                  _initialStep != null &&
                  _initialWidth != null) {
                final deltaX = details.delta.dx;
                final deltaSteps =
                    (deltaX / (Dimens.gridCellWidth * widget.zoom)).round();
                final newStep = (_initialStep! + deltaSteps)
                    .clamp(0, 9999); // Assuming max steps
                widget.onResizeStart(newStep.toDouble());
              }
            },
            onPanEnd: (details) {
              _isResizing = false;
              _initialStep = null;
              _initialWidth = null;
            },
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
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
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            onPanStart: (details) {
              _isResizing = true;
              _initialWidth = widget.width;
            },
            onPanUpdate: (details) {
              if (_isResizing && _initialWidth != null) {
                final deltaX = details.delta.dx;
                final newWidth = (_initialWidth! + deltaX).clamp(
                    Dimens.gridCellWidth * widget.zoom * 0.25, double.infinity);
                final newDuration =
                    newWidth / (Dimens.gridCellWidth * widget.zoom);
                widget.onResizeEnd(newDuration);
              }
            },
            onPanEnd: (details) {
              _isResizing = false;
              _initialWidth = null;
            },
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isResizing) {
      _isMoving = true;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isMoving && !_isResizing && widget.onMove != null) {
      // This will be handled by the parent piano roll widget
      // The note widget just needs to indicate it's being moved
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isMoving = false;
  }

  String _getNoteDisplayName() {
    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final octave = (widget.note.pitch / 12).floor() - 1;
    final noteIndex = widget.note.pitch % 12;
    return '${noteNames[noteIndex]}$octave';
  }

  Color _getTextColor() {
    // Calculate luminance to determine if we should use light or dark text
    final luminance = widget.color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white70;
  }
}
