import 'package:flutter/material.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_state.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart'; // Added for firstWhereOrNull

import '../../../../../core/theme/dimens.dart';
import '../../../logic/piano_roll/piano_roll_notifier.dart';
import '../../../logic/piano_roll/note_drag_data.dart'; // Added import
import '../../../models/note.dart';
import 'piano_roll_grid_painter.dart';
import 'piano_roll_note_widget.dart';

class PianoRollGridWidget extends StatefulWidget {
  final int trackIndex;
  final List<Note> notes;
  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;
  final Function(Note) onNoteCreated;
  final Function(Note) onNoteUpdated;
  final Function(String) onNoteDeleted;
  final Function(Set<String>, {bool addToSelection}) onNotesSelected;

  const PianoRollGridWidget({
    super.key,
    required this.trackIndex,
    required this.notes,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    required this.onNoteCreated,
    required this.onNoteUpdated,
    required this.onNoteDeleted,
    required this.onNotesSelected,
  });

  @override
  State<PianoRollGridWidget> createState() => _PianoRollGridWidgetState();
}

class _PianoRollGridWidgetState extends State<PianoRollGridWidget> {
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  bool _isSelectionBoxActive = false;
  Note? _resizingNote;
  bool _isResizingFromLeft = false;

  GridPosition? _gridPositionForTapAction;
  _PendingTapActionDetails? _pendingTapActionDetails;

  Offset? _resizeGestureStartPanPosition;
  int? _originalStepAtResizeStart;
  int? _originalDurationAtResizeStart;

  @override
  Widget build(BuildContext context) {
    return Consumer<PianoRollNotifier>(
      builder: (context, notifier, child) {
        final state = notifier.value;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) => _handleTapDown(details, notifier),
          onTapUp: (details) =>
              _handleTapUp(details, notifier), // Added for deferred actions
          onPanStart: (details) => _handlePanStart(details, notifier),
          onPanUpdate: (details) => _handlePanUpdate(details, notifier),
          onPanEnd: (details) => _handlePanEnd(details, notifier),
          child: SingleChildScrollView(
            controller: widget.horizontalScrollController,
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SingleChildScrollView(
              controller: widget.verticalScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                width: notifier.totalWidth,
                height: notifier.totalHeight,
                child: Stack(
                  children: [
                    // Grid background
                    CustomPaint(
                      painter: PianoRollGridPainter(
                        cellWidth: notifier.cellWidth,
                        keyHeight: notifier.keyHeight,
                        totalSteps: state.totalSteps,
                        totalKeys: state.totalKeys,
                        stepsPerBar: state.stepsPerBar,
                        lowestNote: state.lowestNote,
                        playheadPosition: state.playheadPosition,
                        loopStart: state.loopStart,
                        loopEnd: state.loopEnd,
                        isLooping: state.isLooping,
                      ),
                      size: Size(notifier.totalWidth, notifier.totalHeight),
                    ),

                    // Notes
                    ...widget.notes.map((note) {
                      return _buildNoteWidget(note, notifier);
                    }),

                    // Selection box
                    if (_isSelectionBoxActive &&
                        _selectionBoxStart != null &&
                        _selectionBoxEnd != null)
                      _buildSelectionBox(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteWidget(Note note, PianoRollNotifier notifier) {
    // This is where the PianoRollNoteWidget's onResizeStart callback is wired.
    // It's assumed that PianoRollNoteWidget will be updated to call:
    // onResizeStart: (fromLeft, globalPosition) => _startNoteResize(note, fromLeft, globalPosition),
    // For now, the existing call is kept, but it will need to be updated in PianoRollNoteWidget
    final keyIndex = note.pitch - notifier.value.lowestNote;
    if (keyIndex < 0 || keyIndex >= notifier.value.totalKeys) {
      return const SizedBox.shrink();
    }

    final position = notifier.gridToScreen(note.step.toDouble(), note.pitch);
    final width = note.duration * notifier.cellWidth;
    final height = notifier.keyHeight - 2;

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: width,
      height: height,
      child: PianoRollNoteWidget(
        note: note,
        isSelected: notifier.isNoteSelected(note.id),
        onTap: () => _handleNoteTap(note, notifier),
        onMove: (delta) => {}, // No-op: movement handled by unified drag system
        onResizeStart: (fromLeft, globalPosition) {
          _onNoteResizeGestureStart(note, globalPosition, fromLeft, notifier);
        },
        onResize: (newDuration, fromLeft) => _handleNoteResize(
            note,
            newDuration,
            fromLeft,
            notifier), // Corrected: onResizeUpdate -> onResize
        onResizeEnd: () => _endNoteResize(),
        onDelete: () => widget.onNoteDeleted(note.id),
        cellWidth: notifier.cellWidth,
      ),
    );
  }

  Widget _buildSelectionBox() {
    if (_selectionBoxStart == null || _selectionBoxEnd == null) {
      return const SizedBox.shrink();
    }

    final left = math.min(_selectionBoxStart!.dx, _selectionBoxEnd!.dx);
    final top = math.min(_selectionBoxStart!.dy, _selectionBoxEnd!.dy);
    final width = (_selectionBoxEnd!.dx - _selectionBoxStart!.dx).abs();
    final height = (_selectionBoxEnd!.dy - _selectionBoxStart!.dy).abs();

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details, PianoRollNotifier notifier) {
    final localPosition = details.localPosition;
    _gridPositionForTapAction = notifier.screenToGrid(localPosition);

    if (!_gridPositionForTapAction!.isValid) {
      _gridPositionForTapAction = null; // Invalidate for TapUp
      return;
    }

    // Reset pending tap actions for Draw mode
    _pendingTapActionDetails = null;

    if (notifier.value.mode == PianoRollMode.draw) {
      // In Draw mode, determine potential action but don't execute yet.
      // Action will be performed in _handleTapUp if no pan occurs.
      final snappedStep =
          notifier.snapToGrid(_gridPositionForTapAction!.step).round();
      final pitch = _gridPositionForTapAction!.pitch;

      final existingNoteAtSnappedPosition = widget.notes
          .where((note) => note.step == snappedStep && note.pitch == pitch)
          .firstOrNull;

      if (existingNoteAtSnappedPosition != null) {
        _pendingTapActionDetails = _PendingTapActionDetails(
          type: _PendingTapActionType.delete,
          position: _gridPositionForTapAction!,
          noteIdToDelete: existingNoteAtSnappedPosition.id,
        );
      } else {
        _pendingTapActionDetails = _PendingTapActionDetails(
          type: _PendingTapActionType.create,
          position: _gridPositionForTapAction!,
        );
      }
    } else if (notifier.value.mode == PianoRollMode.select) {
      // Select mode: toggle selection immediately on TapDown.
      final clickedNote = _findNoteAtPosition(localPosition,
          notifier); // Use original localPosition for finding note
      if (clickedNote != null) {
        notifier.toggleNoteSelection(clickedNote.id);
      } else {
        notifier.deselectAllNotes();
      }
    }
  }

  // Added to handle deferred actions from TapDown, specifically for Draw mode.
  void _handleTapUp(TapUpDetails details, PianoRollNotifier notifier) {
    final pendingAction = _pendingTapActionDetails;

    if (pendingAction != null && pendingAction.position.isValid) {
      if (pendingAction.type == _PendingTapActionType.delete &&
          pendingAction.noteIdToDelete != null) {
        widget.onNoteDeleted(pendingAction.noteIdToDelete!);
      } else if (pendingAction.type == _PendingTapActionType.create) {
        _createNoteAtPosition(pendingAction.position, notifier);
      }
    }

    // Reset tap action state for the next gesture sequence
    _gridPositionForTapAction = null;
    _pendingTapActionDetails = null;
  }

  void _handlePanStart(DragStartDetails details, PianoRollNotifier notifier) {
    // If a pan starts, cancel any pending tap action
    _gridPositionForTapAction = null;
    if (_pendingTapActionDetails != null) {
      _pendingTapActionDetails = null;
    }

    final localPosition = details.localPosition;

    // Check if we're starting to resize a note
    if (_resizingNote != null) {
      return;
    }

    final clickedNote = _findNoteAtPosition(localPosition, notifier);

    if (clickedNote != null && notifier.value.mode == PianoRollMode.select) {
      // If we clicked on a note in select mode
      if (!notifier.isNoteSelected(clickedNote.id)) {
        // Select the note if it wasn't selected
        notifier.selectNote(clickedNote.id);
      }
      // Start dragging selected notes
      if (notifier.hasSelectedNotes()) {
        final GridPosition gridStartPosition =
            notifier.screenToGrid(localPosition);
        notifier.startDragging(
            Offset(gridStartPosition.step, gridStartPosition.pitch.toDouble()),
            widget.notes);
      }
    } else if (notifier.value.mode == PianoRollMode.select &&
        clickedNote == null) {
      // Start selection box only if we didn't click on a note
      _selectionBoxStart = localPosition;
      _selectionBoxEnd = localPosition;
      _isSelectionBoxActive = true;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, PianoRollNotifier notifier) {
    final localPosition = details.localPosition;

    if (_resizingNote != null) {
      // Handle note resizing
      _updateNoteResize(localPosition, notifier);
    } else if (notifier.value.isDragging) {
      // Handle note dragging
      _updateNoteDragging(localPosition, notifier);
    } else if (_isSelectionBoxActive) {
      // Update selection box
      setState(() {
        _selectionBoxEnd = localPosition;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details, PianoRollNotifier notifier) {
    if (_resizingNote != null) {
      _endNoteResize();
    } else if (notifier.value.isDragging) {
      notifier.stopDragging();
    } else if (_isSelectionBoxActive) {
      // Finalize selection box
      _finalizeSelectionBox(notifier);
    }
  }

  void _handleNoteTap(Note note, PianoRollNotifier notifier) {
    if (notifier.value.mode == PianoRollMode.select) {
      notifier.toggleNoteSelection(note.id);
    }
  }

  void _onNoteResizeGestureStart(Note note, Offset globalPosition,
      bool isResizingFromLeft, PianoRollNotifier notifier) {
    // Cancel any pending tap action if a resize drag starts
    if (_pendingTapActionDetails != null) {
      _pendingTapActionDetails = null;
    }

    notifier.startResizing(note);

    // Convert global position to local position relative to this widget
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final localPosition =
        renderBox?.globalToLocal(globalPosition) ?? globalPosition;

    setState(() {
      _resizingNote = note;
      _isResizingFromLeft = isResizingFromLeft;
      _resizeGestureStartPanPosition = localPosition;
      _originalStepAtResizeStart = note.step;
      _originalDurationAtResizeStart = note.duration;
    });
  }

  void _handleNoteResize(Note note, double newDuration, bool fromLeft,
      PianoRollNotifier notifier) {
    final minDuration =
        math.max(Dimens.pianoRollSnapTolerance, notifier.snapToGrid(0.25));
    final maxDuration =
        notifier.value.totalSteps.toDouble() - note.step.toDouble();

    final snappedDuration =
        notifier.snapToGrid(newDuration).clamp(minDuration, maxDuration);

    if (snappedDuration.round() != note.duration) {
      final updatedNote = note.copyWith(duration: snappedDuration.round());
      widget.onNoteUpdated(updatedNote);
    }
  }

  void _endNoteResize() {
    setState(() {
      _resizingNote = null;
      _isResizingFromLeft = false;
      _resizeGestureStartPanPosition = null;
      _originalStepAtResizeStart = null;
      _originalDurationAtResizeStart = null;
    });
  }

  void _updateNoteResize(
      Offset currentPanPosition, PianoRollNotifier notifier) {
    if (_resizingNote == null ||
        _resizeGestureStartPanPosition == null ||
        _originalStepAtResizeStart == null ||
        _originalDurationAtResizeStart == null) {
      return;
    }

    // Calculate the delta in screen pixels
    final deltaX = currentPanPosition.dx - _resizeGestureStartPanPosition!.dx;

    // Convert pixel delta to step delta
    final stepDelta = deltaX / notifier.cellWidth;

    // Calculate minimum duration
    final minDuration = math.max(1, notifier.snapToGrid(0.25).round());

    int newStep = _originalStepAtResizeStart!;
    int newDuration = _originalDurationAtResizeStart!;

    if (_isResizingFromLeft) {
      // When resizing from left, adjust both step and duration
      final proposedStep = _originalStepAtResizeStart! + stepDelta;
      final snappedStep = notifier.snapToGrid(proposedStep);

      // Ensure step doesn't go negative
      newStep = math.max(0, snappedStep.round());

      // Calculate new duration to maintain the right edge
      final originalRightEdge =
          _originalStepAtResizeStart! + _originalDurationAtResizeStart!;
      newDuration = math.max(minDuration, originalRightEdge - newStep);
    } else {
      // When resizing from right, only adjust duration
      final proposedDuration = _originalDurationAtResizeStart! + stepDelta;
      final snappedDuration = notifier.snapToGrid(proposedDuration);

      newDuration = math.max(minDuration, snappedDuration.round());

      // Ensure note doesn't extend beyond total steps
      final maxDuration = notifier.value.totalSteps - newStep;
      newDuration = math.min(newDuration, maxDuration);
    }

    // Only update if there's an actual change
    if (newStep != _resizingNote!.step ||
        newDuration != _resizingNote!.duration) {
      final updatedNote = _resizingNote!.copyWith(
        step: newStep,
        duration: newDuration,
      );
      widget.onNoteUpdated(updatedNote);
      _resizingNote = updatedNote;
    }
  }

  void _updateNoteDragging(
      Offset currentGridPosition, PianoRollNotifier notifier) {
    final Offset? dragStartGridPositionOffset =
        notifier.value.dragStartPosition;
    final Map<String, NoteDragData>? dragStartNoteData =
        notifier.value.dragStartNoteData;

    if (!notifier.value.isDragging ||
        dragStartGridPositionOffset == null ||
        dragStartNoteData == null ||
        dragStartNoteData.isEmpty) {
      return;
    }

    // Convert current screen position to grid coordinates
    final GridPosition currentGridPos =
        notifier.screenToGrid(currentGridPosition);

    // Calculate total displacement in grid units
    final double totalStepDelta =
        currentGridPos.step - dragStartGridPositionOffset.dx;
    final int totalPitchDelta =
        currentGridPos.pitch - dragStartGridPositionOffset.dy.round();

    for (final entry in dragStartNoteData.entries) {
      final noteId = entry.key;
      final initialDragData = entry.value;

      final originalNote = widget.notes.firstWhereOrNull((n) => n.id == noteId);
      if (originalNote == null) {
        continue;
      }

      // Calculate new position based on the note's initial position and total delta
      double newStepDouble = initialDragData.initialStep + totalStepDelta;
      int newPitch = initialDragData.initialPitch + totalPitchDelta;

      // Snap step to grid if enabled
      if (notifier.value.isSnapEnabled &&
          notifier.value.snapResolution != SnapResolution.none) {
        newStepDouble = notifier.snapToGrid(newStepDouble);
      }

      int newSnappedStep = newStepDouble.round();

      // Clamp pitch to valid range
      newPitch =
          newPitch.clamp(notifier.value.lowestNote, notifier.value.highestNote);

      // Clamp step to prevent going out of bounds
      newSnappedStep = newSnappedStep.clamp(
          0, notifier.value.totalSteps - originalNote.duration);

      // Only update if there's an actual change in step or pitch
      if (newSnappedStep != originalNote.step ||
          newPitch != originalNote.pitch) {
        final updatedNote =
            originalNote.copyWith(step: newSnappedStep, pitch: newPitch);
        widget.onNoteUpdated(updatedNote);
      }
    }
  }

  void _finalizeSelectionBox(PianoRollNotifier notifier) {
    if (_selectionBoxStart != null && _selectionBoxEnd != null) {
      final selectedNoteIds = notifier.getNotesInSelectionBox(
        _selectionBoxStart!,
        _selectionBoxEnd!,
        widget.notes,
      );

      widget.onNotesSelected(selectedNoteIds);
    }

    setState(() {
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
      _isSelectionBoxActive = false;
    });
  }

  Note? _findNoteAtPosition(Offset position, PianoRollNotifier notifier) {
    for (final note in widget.notes) {
      final notePosition =
          notifier.gridToScreen(note.step.toDouble(), note.pitch);
      final noteWidth = note.duration * notifier.cellWidth;
      final noteHeight = notifier.keyHeight;

      if (position.dx >= notePosition.dx &&
          position.dx <= notePosition.dx + noteWidth &&
          position.dy >= notePosition.dy &&
          position.dy <= notePosition.dy + noteHeight) {
        return note;
      }
    }
    return null;
  }

  void _createNoteAtPosition(
      GridPosition gridPosition, PianoRollNotifier notifier) {
    final snappedStep = notifier.snapToGrid(gridPosition.step);
    final roundedStep = snappedStep.round();

    // Ensure the pitch is within valid range
    if (gridPosition.pitch < notifier.value.lowestNote ||
        gridPosition.pitch > notifier.value.highestNote) {
      return;
    }

    // Double-check that there's no existing note at this position
    final existingNote = widget.notes
        .where((note) =>
            note.step == roundedStep && note.pitch == gridPosition.pitch)
        .firstOrNull;

    if (existingNote != null) {
      return;
    }

    // Create new note with minimum duration
    final defaultDuration = math.max(notifier.snapToGrid(1.0), 1.0);
    final noteId =
        '${DateTime.now().millisecondsSinceEpoch}_${gridPosition.pitch}_$roundedStep';

    final newNote = Note(
      id: noteId,
      pitch: gridPosition.pitch,
      step: roundedStep,
      duration: defaultDuration.round(),
      velocity: 100,
      trackIndex: widget.trackIndex,
      color: const Color(0xFF2196F3),
    );

    widget.onNoteCreated(newNote);

    notifier.selectNote(newNote.id);
  }
}

// Helper enum and class for deferred tap actions
enum _PendingTapActionType { create, delete }

class _PendingTapActionDetails {
  final _PendingTapActionType type;
  final GridPosition position;
  final String? noteIdToDelete; // Only relevant for delete type

  _PendingTapActionDetails({
    required this.type,
    required this.position,
    this.noteIdToDelete,
  });
}
