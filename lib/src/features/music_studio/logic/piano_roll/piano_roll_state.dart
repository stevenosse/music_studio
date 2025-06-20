import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/note.dart';
import 'note_drag_data.dart';

enum PianoRollTool {
  select,
  draw,
  mute,
}

enum SnapResolution {
  bar(1, 'Bar'),
  beat(4, '1/4'),
  halfBeat(8, '1/8'),
  quarterBeat(16, '1/16'),
  eighthBeat(32, '1/32'),
  sixteenthBeat(64, '1/64'),

  // Triplets
  tripletEighth(12, '1/8T'),
  tripletSixteenth(24, '1/16T'),

  none(0, 'None');

  const SnapResolution(this.divisionsPerBar, this.label);
  final int divisionsPerBar;
  final String label;
}

class PianoRollState extends Equatable {
  const PianoRollState({
    this.selectedNotes = const {},
    this.tool = PianoRollTool.draw,
    this.snapResolution = SnapResolution.quarterBeat,
    this.isSnapEnabled = true,
    this.zoomLevel = 1.0,
    this.horizontalScrollOffset = 0.0,
    this.verticalScrollOffset = 0.0,
    this.showGhostNotes = false,
    this.showVelocityEditor = true,
    this.playheadPosition = 0.0,
    this.loopStart = 0.0,
    this.loopEnd = 32.0,
    this.isLooping = false,
    this.octaveRange = 7,
    this.lowestNote = 24, // C2
    this.previewOnHover = true,
    this.previewOnInsert = true,
    this.isDragging = false,
    this.isResizing = false,
    this.dragStartPosition,
    this.resizeStartNote,
    this.dragStartNoteData,
    this.draggedNotesPreview,
  });

  final Set<String> selectedNotes;
  final PianoRollTool tool;
  final SnapResolution snapResolution;
  final bool isSnapEnabled;
  final double zoomLevel;
  final double horizontalScrollOffset;
  final double verticalScrollOffset;
  final bool showGhostNotes;
  final bool showVelocityEditor;
  final double playheadPosition;
  final double loopStart;
  final double loopEnd;
  final bool isLooping;
  final int octaveRange;
  final int lowestNote;
  final bool previewOnHover;
  final bool previewOnInsert;
  final bool isDragging;
  final bool isResizing;
  final Offset? dragStartPosition;
  final Note? resizeStartNote;
  final Map<String, NoteDragData>? dragStartNoteData;
  final Map<String, Note>? draggedNotesPreview;

  int get totalKeys => octaveRange * 12;
  int get highestNote => lowestNote + totalKeys - 1;

  PianoRollState copyWith({
    Set<String>? selectedNotes,
    PianoRollTool? tool,
    SnapResolution? snapResolution,
    bool? isSnapEnabled,
    double? zoomLevel,
    double? horizontalScrollOffset,
    double? verticalScrollOffset,
    bool? showGhostNotes,
    bool? showVelocityEditor,
    double? playheadPosition,
    double? loopStart,
    double? loopEnd,
    bool? isLooping,
    int? octaveRange,
    int? lowestNote,
    bool? previewOnHover,
    bool? previewOnInsert,
    bool? isDragging,
    bool? isResizing,
    Offset? dragStartPosition,
    Note? resizeStartNote,
    Map<String, NoteDragData>? dragStartNoteData,
    Map<String, Note>? draggedNotesPreview,
  }) {
    return PianoRollState(
      selectedNotes: selectedNotes ?? this.selectedNotes,
      tool: tool ?? this.tool,
      snapResolution: snapResolution ?? this.snapResolution,
      isSnapEnabled: isSnapEnabled ?? this.isSnapEnabled,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      horizontalScrollOffset: horizontalScrollOffset ?? this.horizontalScrollOffset,
      verticalScrollOffset: verticalScrollOffset ?? this.verticalScrollOffset,
      showGhostNotes: showGhostNotes ?? this.showGhostNotes,
      showVelocityEditor: showVelocityEditor ?? this.showVelocityEditor,
      playheadPosition: playheadPosition ?? this.playheadPosition,
      loopStart: loopStart ?? this.loopStart,
      loopEnd: loopEnd ?? this.loopEnd,
      isLooping: isLooping ?? this.isLooping,
      octaveRange: octaveRange ?? this.octaveRange,
      lowestNote: lowestNote ?? this.lowestNote,
      previewOnHover: previewOnHover ?? this.previewOnHover,
      previewOnInsert: previewOnInsert ?? this.previewOnInsert,
      isDragging: isDragging ?? this.isDragging,
      isResizing: isResizing ?? this.isResizing,
      dragStartPosition: dragStartPosition ?? this.dragStartPosition,
      resizeStartNote: resizeStartNote ?? this.resizeStartNote,
      dragStartNoteData: dragStartNoteData ?? this.dragStartNoteData,
      draggedNotesPreview: draggedNotesPreview ?? this.draggedNotesPreview,
    );
  }

  @override
  List<Object?> get props => [
        selectedNotes,
        tool,
        snapResolution,
        isSnapEnabled,
        zoomLevel,
        horizontalScrollOffset,
        verticalScrollOffset,
        showGhostNotes,
        showVelocityEditor,
        playheadPosition,
        loopStart,
        loopEnd,
        isLooping,
        octaveRange,
        lowestNote,
        previewOnHover,
        previewOnInsert,
        isDragging,
        isResizing,
        dragStartPosition,
        resizeStartNote,
        dragStartNoteData,
        draggedNotesPreview,
      ];
}