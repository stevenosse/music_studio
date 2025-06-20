import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_state.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // Added for firstWhereOrNull

import '../../../logic/piano_roll/piano_roll_notifier.dart';
// Added import
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
  final Function(List<Note>) onMultipleNotesUpdated;

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
    required this.onMultipleNotesUpdated,
  });

  @override
  State<PianoRollGridWidget> createState() => _PianoRollGridWidgetState();
}

class _PianoRollGridWidgetState extends State<PianoRollGridWidget> {
  // For selection box
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  bool _isSelectionBoxActive = false;

  // For resizing
  Note? _resizingNote;
  bool _isResizingFromLeft = false;
  Offset? _resizeGestureStartPanPosition;
  int? _originalStepAtResizeStart;
  int? _originalDurationAtResizeStart;

  // For keyboard modifier keys
  final FocusNode _focusNode = FocusNode();
  bool _isModifierKeyPressed = false;

  @override
  void initState() {
    super.initState();
    // Request focus when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _isControlOrCommandPressed(KeyEvent event) {
    return HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        setState(() {
          _isModifierKeyPressed = _isControlOrCommandPressed(event);
        });
      },
      child: Consumer<PianoRollNotifier>(builder: (context, notifier, child) {
        final state = notifier.value;

        return GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(_focusNode),
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) => _handleTapUp(details, notifier),
          onSecondaryTapUp: (details) => _handleSecondaryTapUp(details, notifier),
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
                    ...widget.notes
                        .map((note) => _buildNoteWidget(note, notifier)),
                    if (_isSelectionBoxActive) _buildSelectionBox(),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNoteWidget(Note note, PianoRollNotifier notifier) {
    final keyIndex = note.pitch - notifier.value.lowestNote;
    if (keyIndex < 0 || keyIndex >= notifier.value.totalKeys) {
      return const SizedBox.shrink();
    }

    final position = notifier.gridToScreen(note.step.toDouble(), note.pitch);
    final width = note.duration * notifier.cellWidth;
    final height = notifier.keyHeight;

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: width,
      height: height,
      child: PianoRollNoteWidget(
        note: note,
        isSelected: notifier.isNoteSelected(note.id),
        onResizeStart: (fromLeft, globalPosition) =>
            _onNoteResizeGestureStart(note, globalPosition, fromLeft, notifier),
        onResizeUpdate: (globalPosition) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(globalPosition);
          _updateNoteResize(localPosition, notifier);
        },
        onResizeEnd: () => _onNoteResizeGestureEnd(notifier),
        onDelete: () => widget.onNoteDeleted(note.id),
        cellWidth: notifier.cellWidth,
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
          border: Border.all(
              color: Theme.of(context).colorScheme.primary, width: 1),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  // --- GESTURE HANDLING --- //

  void _handleTapUp(TapUpDetails details, PianoRollNotifier notifier) {
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
            widget.onNotesSelected({clickedNote.id}, addToSelection: false);
          }
        } else {
          notifier.deselectAllNotes();
        }
        break;
      case PianoRollTool.draw:
        if (clickedNote == null) {
          _createNoteAtPosition(gridPos, notifier);
        }
        break;
      case PianoRollTool.mute:
        if (clickedNote != null) {
          final updatedNote = clickedNote.copyWith(isMuted: !clickedNote.isMuted);
          widget.onNoteUpdated(updatedNote);
        }
        break;
    }
  }

  void _handleSecondaryTapUp(TapUpDetails details, PianoRollNotifier notifier) {
    final localPosition = details.localPosition;
    final clickedNote = _findNoteAtPosition(localPosition, notifier);
    if (clickedNote != null) {
      widget.onNoteDeleted(clickedNote.id);
    }
  }

  void _handlePanStart(DragStartDetails details, PianoRollNotifier notifier) {
    if (notifier.value.isResizing) return;

    final localPosition = details.localPosition;
    final clickedNote = _findNoteAtPosition(localPosition, notifier);

    if (clickedNote != null) {
      // If a note is clicked, start dragging, regardless of tool.
      if (!notifier.isNoteSelected(clickedNote.id)) {
        widget.onNotesSelected({clickedNote.id}, addToSelection: _isModifierKeyPressed);
      }
      final gridStartPosition = notifier.screenToGrid(localPosition);
      notifier.startDragging(
        Offset(gridStartPosition.step, gridStartPosition.pitch.toDouble()),
        widget.notes,
      );
    } else {
      // If empty space is clicked, only start a selection box in select mode.
      if (notifier.value.tool == PianoRollTool.select) {
        notifier.deselectAllNotes();
        setState(() {
          _selectionBoxStart = localPosition;
          _selectionBoxEnd = localPosition;
          _isSelectionBoxActive = true;
        });
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, PianoRollNotifier notifier) {
    final localPosition = details.localPosition;

    if (notifier.value.isResizing) {
      _updateNoteResize(localPosition, notifier);
    } else if (notifier.value.isDragging) {
      _updateNoteDragging(localPosition, notifier);
    } else if (_isSelectionBoxActive) {
      setState(() {
        _selectionBoxEnd = localPosition;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details, PianoRollNotifier notifier) {
    if (notifier.value.isResizing) {
      _onNoteResizeGestureEnd(notifier);
    } else if (notifier.value.isDragging) {
      notifier.stopDragging();
    } else if (_isSelectionBoxActive) {
      _finalizeSelectionBox(notifier);
    }
  }

  // --- ACTION IMPLEMENTATIONS --- //

  void _updateNoteDragging(Offset currentPosition, PianoRollNotifier notifier) {
    final state = notifier.value;
    if (!state.isDragging ||
        state.dragStartPosition == null ||
        state.dragStartNoteData == null) {
      return;
    }

    final currentGridPos = notifier.screenToGrid(currentPosition);
    final startGridPos = state.dragStartPosition!;
    final stepDelta = currentGridPos.step - startGridPos.dx;
    final pitchDelta = currentGridPos.pitch - startGridPos.dy.round();

    final updatedNotes = <Note>[];
    final notesToUpdate =
        widget.notes.where((n) => state.selectedNotes.contains(n.id));

    for (final noteToUpdate in notesToUpdate) {
      final dragData = state.dragStartNoteData![noteToUpdate.id];
      if (dragData == null) continue;

      final newStepDouble = dragData.initialStep + stepDelta;
      final newPitch = dragData.initialPitch + pitchDelta;

      final snappedStep = notifier.snapToGrid(newStepDouble).round();
      final clampedPitch = newPitch.clamp(state.lowestNote, state.highestNote);
      final clampedStep =
          snappedStep.clamp(0, state.totalSteps - noteToUpdate.duration);

      if (clampedStep != noteToUpdate.step ||
          clampedPitch != noteToUpdate.pitch) {
        updatedNotes
            .add(noteToUpdate.copyWith(step: clampedStep, pitch: clampedPitch));
      }
    }

    if (updatedNotes.isNotEmpty) {
      widget.onMultipleNotesUpdated(updatedNotes);
    }
  }

  void _finalizeSelectionBox(PianoRollNotifier notifier) {
    if (_selectionBoxStart == null || _selectionBoxEnd == null) return;

    final selectedIds = notifier.getNotesInSelectionBox(
      _selectionBoxStart!,
      _selectionBoxEnd!,
      widget.notes,
    );
    widget.onNotesSelected(selectedIds, addToSelection: false);

    setState(() {
      _isSelectionBoxActive = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
    });
  }

  void _onNoteResizeGestureStart(Note note, Offset globalPosition,
      bool isResizingFromLeft, PianoRollNotifier notifier) {
    notifier.startResizing(note);
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);

    setState(() {
      _resizingNote = note;
      _isResizingFromLeft = isResizingFromLeft;
      _resizeGestureStartPanPosition = localPosition;
      _originalStepAtResizeStart = note.step;
      _originalDurationAtResizeStart = note.duration;
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

    final deltaX = currentPanPosition.dx - _resizeGestureStartPanPosition!.dx;
    final stepDelta = deltaX / notifier.cellWidth;

    int newStep = _originalStepAtResizeStart!;
    int newDuration = _originalDurationAtResizeStart!;

    if (_isResizingFromLeft) {
      // Calculate the new potential start step and snap it to the grid
      final potentialNewStepDouble = _originalStepAtResizeStart! + stepDelta;
      final snappedNewStep =
          notifier.snapToGrid(potentialNewStepDouble).round();

      // Calculate the change in steps and the resulting new duration
      final snappedStepChange = snappedNewStep - _originalStepAtResizeStart!;
      final potentialNewDuration =
          _originalDurationAtResizeStart! - snappedStepChange;

      // Apply changes if valid (duration >= 1 and left handle doesn't cross right handle)
      if (potentialNewDuration >= 1 &&
          snappedNewStep <
              (_originalStepAtResizeStart! + _originalDurationAtResizeStart!)) {
        newStep = snappedNewStep;
        newDuration = potentialNewDuration;
      }
    } else {
      // Resizing from the right
      // Calculate the new potential end step and snap it to the grid
      final originalEndStep =
          _originalStepAtResizeStart! + _originalDurationAtResizeStart!;
      final potentialNewEndStepDouble = originalEndStep + stepDelta;
      final snappedNewEndStep =
          notifier.snapToGrid(potentialNewEndStepDouble).round();

      // Calculate the new duration from the snapped end position
      final potentialNewDuration =
          snappedNewEndStep - _originalStepAtResizeStart!;

      // Apply change if valid (duration >= 1)
      if (potentialNewDuration >= 1) {
        newDuration = potentialNewDuration;
      }
    }

    final state = notifier.value;
    // Clamp step and duration to the piano roll boundaries
    newStep = newStep.clamp(0, state.totalSteps - 1);
    newDuration = newDuration.clamp(1, state.totalSteps - newStep);

    if (newStep != _resizingNote!.step ||
        newDuration != _resizingNote!.duration) {
      final updatedNote =
          _resizingNote!.copyWith(step: newStep, duration: newDuration);
      widget.onNoteUpdated(updatedNote);
    }
  }

  void _onNoteResizeGestureEnd(PianoRollNotifier notifier) {
    notifier.stopResizing();
    setState(() {
      _resizingNote = null;
      _isResizingFromLeft = false;
      _resizeGestureStartPanPosition = null;
      _originalStepAtResizeStart = null;
      _originalDurationAtResizeStart = null;
    });
  }

  Note? _findNoteAtPosition(Offset localPosition, PianoRollNotifier notifier) {
    final gridPos = notifier.screenToGrid(localPosition);
    if (!gridPos.isValid) return null;

    return widget.notes.firstWhereOrNull((note) {
      return note.pitch == gridPos.pitch &&
          gridPos.step >= note.step &&
          gridPos.step < (note.step + note.duration);
    });
  }

  void _createNoteAtPosition(GridPosition gridPos, PianoRollNotifier notifier) {
    final snappedStep = notifier.snapToGrid(gridPos.step).round();

    const defaultDuration = 1;

    final newNote = Note(
      id: UniqueKey().toString(),
      pitch: gridPos.pitch,
      step: snappedStep,
      duration: defaultDuration,
      velocity: 100,
      trackIndex: widget.trackIndex,
      color: const Color(0xFF2196F3),
    );

    widget.onNoteCreated(newNote);
    // Select the newly created note, clearing previous selections.
    widget.onNotesSelected({newNote.id}, addToSelection: false);
  }
}
