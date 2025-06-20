import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart'; // Added for firstWhereOrNull
import '../../../../core/theme/dimens.dart';
import '../../models/note.dart';
import 'piano_roll_state.dart';
import 'note_drag_data.dart'; // Added import

class PianoRollNotifier extends ValueNotifier<PianoRollState> {
  PianoRollNotifier() : super(const PianoRollState());

  // Grid calculations
  double get cellWidth => Dimens.gridCellWidth * value.zoomLevel;
  double get keyHeight => Dimens.pianoRollKeyHeight;
  double get totalWidth => cellWidth * value.totalSteps;
  double get totalHeight => keyHeight * value.totalKeys;

  // Snap to grid functionality
  double snapToGrid(double position) {
    if (!value.isSnapEnabled || value.snapResolution == SnapResolution.none) {
      return position;
    }
    
    final snapValue = value.snapValue;
    return (position / snapValue).round() * snapValue;
  }

  // Convert screen position to grid coordinates
  GridPosition screenToGrid(Offset screenPosition) {
    // Add scroll offsets to convert screen position to absolute position within the scrollable content
    final absoluteX = screenPosition.dx + value.horizontalScrollOffset;
    final absoluteY = screenPosition.dy + value.verticalScrollOffset;

    final step = absoluteX / cellWidth;
    final keyIndex = (absoluteY / keyHeight).floor();

    // Calculate pitch from the top of the grid
    final pitch = value.totalKeys - 1 - keyIndex + value.lowestNote;

    return GridPosition(step: step, pitch: pitch, keyIndex: keyIndex);
  }

  // Convert grid coordinates to screen position
  Offset gridToScreen(double step, int pitch) {
    // Calculate keyIndex from bottom: reverse of pitch calculation
    final keyIndex = value.totalKeys - 1 - (pitch - value.lowestNote);
    // Convert grid coordinates to absolute position within the scrollable content
    final x = step * cellWidth;
    final y = keyIndex * keyHeight;
    return Offset(x, y);
  }

  // --- Tool and Snap Management ---

  void setTool(PianoRollTool tool) {
    if (value.tool == tool) return;
    value = value.copyWith(tool: tool);
  }

  // Snap settings
  void setSnapResolution(SnapResolution resolution) {
    value = value.copyWith(snapResolution: resolution);
  }

  void toggleSnap() {
    value = value.copyWith(isSnapEnabled: !value.isSnapEnabled);
  }

  // Zoom functionality
  void zoomIn() {
    final newZoom = math.min(
      value.zoomLevel + Dimens.pianoRollZoomStep,
      Dimens.pianoRollMaxZoom,
    );
    value = value.copyWith(zoomLevel: newZoom);
  }

  void zoomOut() {
    final newZoom = math.max(
      value.zoomLevel - Dimens.pianoRollZoomStep,
      Dimens.pianoRollMinZoom,
    );
    value = value.copyWith(zoomLevel: newZoom);
  }

  void setZoom(double zoom) {
    final clampedZoom = zoom.clamp(Dimens.pianoRollMinZoom, Dimens.pianoRollMaxZoom);
    value = value.copyWith(zoomLevel: clampedZoom);
  }

  // Scroll management
  void setHorizontalScroll(double offset) {
    value = value.copyWith(horizontalScrollOffset: offset);
  }

  void setVerticalScroll(double offset) {
    value = value.copyWith(verticalScrollOffset: offset);
  }

  // Note selection
  void selectNote(String noteId) {
    final newSelection = Set<String>.from(value.selectedNotes)..add(noteId);
    value = value.copyWith(selectedNotes: newSelection);
  }

  void deselectNote(String noteId) {
    final newSelection = Set<String>.from(value.selectedNotes)..remove(noteId);
    value = value.copyWith(selectedNotes: newSelection);
  }

  void toggleNoteSelection(String noteId) {
    if (value.selectedNotes.contains(noteId)) {
      deselectNote(noteId);
    } else {
      selectNote(noteId);
    }
  }

  void selectMultipleNotes(Set<String> noteIds, {bool addToSelection = false}) {
    final newSelection = addToSelection 
        ? <String>{...value.selectedNotes, ...noteIds}
        : Set<String>.from(noteIds);
    value = value.copyWith(selectedNotes: newSelection);
  }

  void selectAllNotes(List<Note> allNotes) {
    final allNoteIds = allNotes.map((note) => note.id).toSet();
    value = value.copyWith(selectedNotes: allNoteIds);
  }

  void deselectAllNotes() {
    value = value.copyWith(selectedNotes: const {});
  }

  // Selection box
  Set<String> getNotesInSelectionBox(
    Offset startPosition,
    Offset endPosition,
    List<Note> allNotes,
  ) {
    final left = math.min(startPosition.dx, endPosition.dx);
    final right = math.max(startPosition.dx, endPosition.dx);
    final top = math.min(startPosition.dy, endPosition.dy);
    final bottom = math.max(startPosition.dy, endPosition.dy);

    final selectedNoteIds = <String>{};
    
    for (final note in allNotes) {
      // Convert note position to screen coordinates
      final notePosition = gridToScreen(note.step.toDouble(), note.pitch);
      final noteWidth = note.duration * cellWidth;
      final noteRight = notePosition.dx + noteWidth;
      final noteBottom = notePosition.dy + keyHeight;

      // Check if note intersects with selection box
      if (notePosition.dx < right &&
          noteRight > left &&
          notePosition.dy < bottom &&
          noteBottom > top) {
        selectedNoteIds.add(note.id);
      }
    }

    return selectedNoteIds;
  }

  // Drag and drop state
  void startDragging(Offset position, List<Note> allNotesInTrack) {
    final notesToDragData = <String, NoteDragData>{};
    for (final noteId in value.selectedNotes) {
      final noteToDrag = allNotesInTrack.firstWhereOrNull((n) => n.id == noteId);
      if (noteToDrag != null) {
        notesToDragData[noteId] = NoteDragData(
          initialStep: noteToDrag.step,
          initialPitch: noteToDrag.pitch,
        );
      }
    }

    value = value.copyWith(
      isDragging: true,
      dragStartPosition: position,
      dragStartNoteData: notesToDragData,
    );
  }

  void stopDragging() {
    value = value.copyWith(
      isDragging: false,
      dragStartPosition: null,
      dragStartNoteData: null, // Clear dragStartNoteData
    );
  }

  // Resize state
  void startResizing(Note note) {
    value = value.copyWith(
      isResizing: true,
      resizeStartNote: note,
    );
  }

  void stopResizing() {
    value = value.copyWith(
      isResizing: false,
      resizeStartNote: null,
    );
  }

  // Playhead and looping
  void setPlayheadPosition(double position) {
    value = value.copyWith(playheadPosition: position);
  }

  void setLoopRegion(double start, double end) {
    value = value.copyWith(
      loopStart: math.min(start, end),
      loopEnd: math.max(start, end),
    );
  }

  void toggleLooping() {
    value = value.copyWith(isLooping: !value.isLooping);
  }

  // Ghost notes
  void toggleGhostNotes() {
    value = value.copyWith(showGhostNotes: !value.showGhostNotes);
  }

  // Velocity editor
  void toggleVelocityEditor() {
    value = value.copyWith(showVelocityEditor: !value.showVelocityEditor);
  }

  // Preview settings
  void togglePreviewOnHover() {
    value = value.copyWith(previewOnHover: !value.previewOnHover);
  }

  void togglePreviewOnInsert() {
    value = value.copyWith(previewOnInsert: !value.previewOnInsert);
  }

  // Utility methods
  bool isNoteSelected(String noteId) {
    return value.selectedNotes.contains(noteId);
  }

  bool hasSelectedNotes() {
    return value.selectedNotes.isNotEmpty;
  }

  int getSelectedNotesCount() {
    return value.selectedNotes.length;
  }

  // Quantization
  double quantizePosition(double position) {
    return snapToGrid(position);
  }

  Note quantizeNote(Note note) {
    return note.copyWith(
      step: snapToGrid(note.step.toDouble()).round(),
      duration: snapToGrid(note.duration.toDouble()).round(),
    );
  }

  List<Note> quantizeSelectedNotes(List<Note> allNotes) {
    return allNotes.map((note) {
      if (value.selectedNotes.contains(note.id)) {
        return quantizeNote(note);
      }
      return note;
    }).toList();
  }
}

class GridPosition {
  const GridPosition({
    required this.step,
    required this.pitch,
    required this.keyIndex,
  });

  final double step;
  final int pitch;
  final int keyIndex;

  @override
  String toString() {
    return 'GridPosition(step: ${step.toStringAsFixed(2)}, pitch: $pitch)';
  }

  bool get isValid => pitch >= 0 && pitch <= 127 && step >= 0;
}