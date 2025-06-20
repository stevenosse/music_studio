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
  quarter(4, '1/4'),
  eighth(8, '1/8'),
  sixteenth(16, '1/16'),
  thirtySecond(32, '1/32'),
  triplets(12, 'Triplets'),
  none(0, 'None');

  const SnapResolution(this.divisionsPerBeat, this.label);
  final int divisionsPerBeat;
  final String label;
}

class PianoRollState extends Equatable {
  const PianoRollState({
    this.selectedNotes = const {},
    this.tool = PianoRollTool.draw,
    this.snapResolution = SnapResolution.sixteenth,
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
    this.stepsPerBar = 16,
    this.totalSteps = 32,
    this.previewOnHover = true,
    this.previewOnInsert = true,
    this.isDragging = false,
    this.isResizing = false,
    this.dragStartPosition,
    this.resizeStartNote,
    this.dragStartNoteData,
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
  final int stepsPerBar;
  final int totalSteps;
  final bool previewOnHover;
  final bool previewOnInsert;
  final bool isDragging;
  final bool isResizing;
  final Offset? dragStartPosition;
  final Note? resizeStartNote;
  final Map<String, NoteDragData>? dragStartNoteData;

  int get totalKeys => octaveRange * 12;
  int get highestNote => lowestNote + totalKeys - 1;
  double get snapValue => isSnapEnabled ? 1.0 / snapResolution.divisionsPerBeat : 0.0;

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
    int? stepsPerBar,
    int? totalSteps,
    bool? previewOnHover,
    bool? previewOnInsert,
    bool? isDragging,
    bool? isResizing,
    Offset? dragStartPosition,
    Note? resizeStartNote,
    Map<String, NoteDragData>? dragStartNoteData,
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
      stepsPerBar: stepsPerBar ?? this.stepsPerBar,
      totalSteps: totalSteps ?? this.totalSteps,
      previewOnHover: previewOnHover ?? this.previewOnHover,
      previewOnInsert: previewOnInsert ?? this.previewOnInsert,
      isDragging: isDragging ?? this.isDragging,
      isResizing: isResizing ?? this.isResizing,
      dragStartPosition: dragStartPosition ?? this.dragStartPosition,
      resizeStartNote: resizeStartNote ?? this.resizeStartNote,
      dragStartNoteData: dragStartNoteData ?? this.dragStartNoteData,
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
        stepsPerBar,
        totalSteps,
        previewOnHover,
        previewOnInsert,
        isDragging,
        isResizing,
        dragStartPosition,
        resizeStartNote,
        dragStartNoteData,
      ];
}