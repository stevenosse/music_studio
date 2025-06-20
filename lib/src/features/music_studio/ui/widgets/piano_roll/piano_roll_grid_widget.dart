import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../logic/music_studio_notifier.dart';
import '../../../logic/piano_roll/piano_roll_notifier.dart';
import '../../../logic/piano_roll/piano_roll_state.dart';
import '../../../models/note.dart';
import '../../../models/track.dart';
import 'piano_roll_grid_painter.dart';
import 'piano_roll_note_widget.dart';

class PianoRollGridWidget extends StatefulWidget {
  const PianoRollGridWidget({
    super.key,
    required this.track,
    required this.trackIndex,
    required this.stepsPerBar,
  });

  final Track track;
  final int trackIndex;
  final int stepsPerBar;

  @override
  State<PianoRollGridWidget> createState() => _PianoRollGridWidgetState();
}

class _PianoRollGridWidgetState extends State<PianoRollGridWidget> {
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;

  Note? _resizingNote;
  bool _isResizingFromLeft = false;
  Offset? _resizeStartPosition;
  int? _originalStepAtResizeStart;
  int? _originalDurationAtResizeStart;

  bool get _isSelectionBoxActive =>
      _selectionBoxStart != null && _selectionBoxEnd != null;

  bool get _isModifierKeyPressed =>
      HardwareKeyboard.instance.isShiftPressed ||
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isMetaPressed;

  @override
  Widget build(BuildContext context) {
    final musicStudioNotifier = context.watch<MusicStudioNotifier>();
    final pianoRollNotifier = context.watch<PianoRollNotifier>();
    final pianoRollState = pianoRollNotifier.value;

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          // Future: Implement mouse wheel scrolling for zoom or navigation
        }
      },
      child: GestureDetector(
        onTapUp: (details) => _handleTapUp(details, context),
        onSecondaryTapUp: (details) => _handleSecondaryTapUp(details, context),
        onPanStart: (details) => _handlePanStart(details, context),
        onPanUpdate: (details) => _handlePanUpdate(details, context),
        onPanEnd: (details) => _handlePanEnd(details, context),
        child: Stack(
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: PianoRollGridPainter(
                  cellWidth: pianoRollNotifier.cellWidth,
                  keyHeight: pianoRollNotifier.keyHeight,
                  totalSteps: pianoRollNotifier.totalSteps,
                  totalKeys: pianoRollState.totalKeys,
                  stepsPerBar: widget.stepsPerBar,
                  lowestNote: pianoRollState.lowestNote,
                  playheadPosition:
                      musicStudioNotifier.value.currentStep.toDouble(),
                  loopStart: pianoRollState.loopStart,
                  loopEnd: pianoRollState.loopEnd,
                  isLooping: pianoRollState.isLooping,
                  snapResolution: pianoRollState.snapResolution,
                ),
                size: Size(
                    pianoRollNotifier.totalWidth, pianoRollNotifier.totalHeight),
              ),
            ),
            ...widget.track.notes
                .map((note) => _buildNoteWidget(note, context)),
            if (_isSelectionBoxActive) _buildSelectionBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteWidget(Note note, BuildContext context) {
    final pianoRollNotifier = context.read<PianoRollNotifier>();
    final pianoRollState = pianoRollNotifier.value;

    Note noteToDisplay = note; // Start with the original note from the track

    // Prioritize dragged note preview if active
    if (pianoRollState.isDragging &&
        pianoRollState.draggedNotesPreview?.containsKey(note.id) == true) {
      noteToDisplay = pianoRollState.draggedNotesPreview![note.id]!;
    } 
    // Else, prioritize resizing note preview if active for this note
    else if (pianoRollState.isResizing && _resizingNote?.id == note.id) {
      noteToDisplay = _resizingNote!;
    }

    return Positioned(
      left: noteToDisplay.step * pianoRollNotifier.cellWidth,
      top: (pianoRollState.totalKeys -
              1 -
              (noteToDisplay.pitch - pianoRollState.lowestNote)) *
          pianoRollNotifier.keyHeight,
      width: noteToDisplay.duration * pianoRollNotifier.cellWidth,
      height: pianoRollNotifier.keyHeight,
      child: PianoRollNoteWidget(
        note: noteToDisplay,
        isSelected: pianoRollState.selectedNotes.contains(note.id),
        cellWidth: pianoRollNotifier.cellWidth,
        onDelete: () =>
            context.read<MusicStudioNotifier>().deleteNote(note.id),
        onResizeStart: (isLeft, details) =>
            _onNoteResizeStart(note, isLeft, details, context),
        onResizeUpdate: (Offset globalPosition) =>
            _onNoteResizeUpdate(globalPosition, context),
        onResizeEnd: () => _onNoteResizeEnd(context),
      ),
    );
  }

  Widget _buildSelectionBox() {
    if (_selectionBoxStart == null || _selectionBoxEnd == null) {
      return const SizedBox.shrink();
    }
    final rect = Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);
    return Positioned.fromRect(
      rect: rect,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withAlpha((255 * 0.2).round()),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
        ),
      ),
    );
  }

  void _handleTapUp(TapUpDetails details, BuildContext context) {
    final notifier = context.read<PianoRollNotifier>();
    if (notifier.value.isResizing) return;

    final localPosition = details.localPosition;
    final gridPos = notifier.screenToGrid(localPosition);
    if (!gridPos.isValid) return;

    final clickedNote = _findNoteAtPosition(localPosition, notifier);

    switch (notifier.value.tool) {
      case PianoRollTool.select:
        if (clickedNote != null) {
          if (_isModifierKeyPressed) {
            notifier.toggleNoteSelection(clickedNote.id);
          } else {
            notifier.selectNote(clickedNote.id, exclusive: true);
          }
        } else {
          notifier.deselectAllNotes();
        }
        break;
      case PianoRollTool.draw:
        if (clickedNote == null) {
          _createNoteAtPosition(gridPos, context);
        }
        break;
      case PianoRollTool.mute:
        if (clickedNote != null) {
          final updatedNote =
              clickedNote.copyWith(isMuted: !clickedNote.isMuted);
          context.read<MusicStudioNotifier>().updateNote(updatedNote);
        }
        break;
    }
  }

  void _handleSecondaryTapUp(TapUpDetails details, BuildContext context) {
    final notifier = context.read<PianoRollNotifier>();
    if (notifier.value.isResizing) return;

    final clickedNote = _findNoteAtPosition(details.localPosition, notifier);
    if (clickedNote != null) {
      context.read<MusicStudioNotifier>().deleteNote(clickedNote.id);
    }
  }

  void _handlePanStart(DragStartDetails details, BuildContext context) {
    final notifier = context.read<PianoRollNotifier>();
    if (notifier.value.isResizing) return;

    final localPosition = details.localPosition;

    switch (notifier.value.tool) {
      case PianoRollTool.select:
        final clickedNote = _findNoteAtPosition(localPosition, notifier);
        if (clickedNote != null) {
          // A note was clicked, initiate note dragging
          if (!notifier.isNoteSelected(clickedNote.id)) {
            notifier.selectNote(clickedNote.id, exclusive: !_isModifierKeyPressed);
          }
          // Ensure selection box is not active if we are about to drag a note.
          if (_selectionBoxStart != null) {
            setState(() {
              _selectionBoxStart = null;
            });
          }
          notifier.startDragging(localPosition, widget.track.notes);
        } else {
          // No note was clicked, initiate selection box
          if (!_isModifierKeyPressed) {
            notifier.deselectAllNotes();
          }
          setState(() {
            _selectionBoxStart = localPosition;
            _selectionBoxEnd = localPosition;
          });
        }
        break;
      case PianoRollTool.draw:
        // TODO: Implement pan-to-draw note logic or other drag behavior for Draw tool
        break;
      case PianoRollTool.mute:
        // Panning with mute tool probably does nothing, or could be used for drag-muting.
        break;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, BuildContext context) {
    final notifier = context.read<PianoRollNotifier>();

    if (notifier.value.isResizing) {
      // Resize is handled by callbacks from PianoRollNoteWidget
      return;
    } else if (notifier.value.isDragging) {
      // Pass the raw local position for delta calculation
      _updateNoteDragging(details.localPosition, context);
    } else if (_isSelectionBoxActive) {
      setState(() {
        _selectionBoxEnd = details.localPosition;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details, BuildContext context) {
    final notifier = context.read<PianoRollNotifier>();
    if (notifier.value.isResizing) {
      _onNoteResizeEnd(context); // Finalize resize state
    } else if (notifier.value.isDragging) {
      notifier.stopDragging();
    } else if (_isSelectionBoxActive) {
      _finalizeSelectionBox(context);
    }
  }

  void _updateNoteDragging(Offset currentPosition, BuildContext context) {
    final notifier = context.read<PianoRollNotifier>();
    final state = notifier.value;

    if (!state.isDragging ||
        state.dragStartPosition == null ||
        state.dragStartNoteData == null) {
      return;
    }

    // Calculate pixel deltas from the drag start position
    final deltaX = currentPosition.dx - state.dragStartPosition!.dx;
    final deltaY = currentPosition.dy - state.dragStartPosition!.dy;

    // print('--- Drag Update ---');
    // print('Current Pos: $currentPosition, Start Pos: ${state.dragStartPosition}');
    // print('Delta X: $deltaX, Delta Y: $deltaY');

    final updatedNotes = <Note>[];
    final notesToUpdate =
        widget.track.notes.where((n) => state.selectedNotes.contains(n.id));

    for (final noteToUpdate in notesToUpdate) {
      final dragData = state.dragStartNoteData![noteToUpdate.id];
      if (dragData == null) continue;

      // Calculate new step based on X delta
      final stepOffset = deltaX / notifier.cellWidth; // Convert pixel delta to step delta
      final newStepDouble = dragData.initialStep + stepOffset;
      final snappedStep = notifier.snapToGrid(newStepDouble).round();
      // print('Note ID: ${noteToUpdate.id}');
      // print('  Initial Step: ${dragData.initialStep}, Step Offset: $stepOffset, New Step Double: $newStepDouble, Snapped: $snappedStep');

      // Calculate new pitch based on Y delta
      // deltaY is positive for downward mouse movement (which means lower pitch)
      // keyHeight is pixels per key
      // So, (deltaY / notifier.keyHeight).round() is the number of keys the mouse has moved vertically
      final pitchDeltaInKeys = (deltaY / notifier.keyHeight).round();
      final newRawPitch = dragData.initialPitch - pitchDeltaInKeys; // Subtract delta because positive deltaY means pitch goes down
      // print('  Initial Pitch: ${dragData.initialPitch}, Pitch Delta Keys: $pitchDeltaInKeys, New Raw Pitch: $newRawPitch');

      final int finalNewPitch = newRawPitch.clamp(state.lowestNote, state.highestNote);
      final clampedStep =
          snappedStep.clamp(0, notifier.totalSteps - noteToUpdate.duration);
      // print('  Final New Pitch: $finalNewPitch, Clamped Step: $clampedStep');
      // print('  Original Note Step: ${noteToUpdate.step}, Pitch: ${noteToUpdate.pitch}');

      if (clampedStep != noteToUpdate.step ||
          finalNewPitch != noteToUpdate.pitch) {
        updatedNotes.add(noteToUpdate.copyWith(step: clampedStep, pitch: finalNewPitch));
      }
    }

    if (updatedNotes.isNotEmpty) {
      notifier.updateDraggedNotesPreview(updatedNotes);
    }
  }

  void _finalizeSelectionBox(BuildContext context) {
    if (_selectionBoxStart == null || _selectionBoxEnd == null) return;
    final notifier = context.read<PianoRollNotifier>();

    final selectedIds = notifier.getNotesInSelectionBox(
      _selectionBoxStart!,
      _selectionBoxEnd!,
      widget.track.notes,
    );
    notifier.selectMultipleNotes(selectedIds,
        addToSelection: _isModifierKeyPressed);

    setState(() {
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
    });
  }

  void _onNoteResizeStart(
      Note note, bool isLeft, DragStartDetails details, BuildContext context) {
    context.read<PianoRollNotifier>().startResizing(note);
    setState(() {
      _resizingNote = note;
      _isResizingFromLeft = isLeft;
      _resizeStartPosition = details.globalPosition;
      _originalStepAtResizeStart = note.step;
      _originalDurationAtResizeStart = note.duration;
    });
  }

  void _onNoteResizeUpdate(Offset globalPosition, BuildContext context) {
    if (_resizingNote == null ||
        _resizeStartPosition == null ||
        _originalDurationAtResizeStart == null ||
        _originalStepAtResizeStart == null) {
      return;
    }

    final notifier = context.read<PianoRollNotifier>();
    final dragDelta = globalPosition - _resizeStartPosition!;
    final stepDelta = dragDelta.dx / notifier.cellWidth;

    setState(() {
      int newStep = _resizingNote!.step;
      int newDuration = _resizingNote!.duration;

      if (_isResizingFromLeft) {
        final newStartStepDouble = _originalStepAtResizeStart! + stepDelta;
        final snappedNewStartStep = notifier.snapToGrid(newStartStepDouble).round();

        final stepChange = snappedNewStartStep - _originalStepAtResizeStart!;
        final potentialNewDuration = _originalDurationAtResizeStart! - stepChange;

        if (potentialNewDuration >= 1 &&
            snappedNewStartStep <
                (_originalStepAtResizeStart! + _originalDurationAtResizeStart!)) {
          newStep = snappedNewStartStep;
          newDuration = potentialNewDuration;
        }
      } else { // Resizing from right
        final originalEndStep = _originalStepAtResizeStart! + _originalDurationAtResizeStart!;
        final newEndStepDouble = originalEndStep + stepDelta;
        final snappedNewEndStep = notifier.snapToGrid(newEndStepDouble).round();

        final potentialNewDuration = snappedNewEndStep - _originalStepAtResizeStart!;
        if (potentialNewDuration >= 1) {
          newDuration = potentialNewDuration;
        }
      }

      // Clamp values to be safe
      newStep = newStep.clamp(0, notifier.totalSteps - 1);
      newDuration = newDuration.clamp(1, notifier.totalSteps - newStep);

      _resizingNote = _resizingNote!.copyWith(step: newStep, duration: newDuration);
    });
  }

  void _onNoteResizeEnd(BuildContext context) {
    if (_resizingNote != null) {
      context.read<MusicStudioNotifier>().updateNote(_resizingNote!);
      context.read<PianoRollNotifier>().stopResizing();
      setState(() {
        _resizingNote = null;
        _isResizingFromLeft = false;
        _resizeStartPosition = null;
        _originalStepAtResizeStart = null;
        _originalDurationAtResizeStart = null;
      });
    }
  }

  Note? _findNoteAtPosition(Offset localPosition, PianoRollNotifier notifier) {
    final gridPos = notifier.screenToGrid(localPosition);
    if (!gridPos.isValid) return null;

    return widget.track.notes.lastWhereOrNull((note) {
      return note.pitch == gridPos.pitch &&
          gridPos.step >= note.step &&
          gridPos.step < (note.step + note.duration);
    });
  }

  void _createNoteAtPosition(GridPosition gridPos, BuildContext context) {
    final notifier = context.read<PianoRollNotifier>();
    final musicStudioNotifier = context.read<MusicStudioNotifier>();
    final snappedStep = notifier.snapToGrid(gridPos.step).round();

    final newNote = Note(
      id: UniqueKey().toString(),
      pitch: gridPos.pitch,
      step: snappedStep,
      duration: notifier.snapValue.round().clamp(1, notifier.totalSteps),
      velocity: 100,
      trackIndex: widget.trackIndex,
      color: widget.track.color,
    );

    musicStudioNotifier.addNote(newNote);
    notifier.selectNote(newNote.id, exclusive: true);
  }
}
