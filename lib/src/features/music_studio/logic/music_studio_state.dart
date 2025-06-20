import 'package:equatable/equatable.dart';
import 'package:mstudio/src/features/music_studio/models/sample_pack.dart';

import '../models/track.dart';

class MusicStudioState extends Equatable {
  const MusicStudioState({
    this.tracks = const [],
    this.selectedTrackIndex = 0,
    this.isPlaying = false,
    this.isRecording = false,
    this.currentStep = 0,
    this.bpm = 120,
    this.stepsPerBar = 32,
    this.projectName = 'Untitled Project',
    this.hasUnsavedChanges = false,
    this.samplePacks = const [],
    this.soundfonts = const [],
  });

  final List<Track> tracks;
  final int selectedTrackIndex;
  final bool isPlaying;
  final bool isRecording;
  final int currentStep;
  final int bpm;
  final int stepsPerBar;
  final String projectName;
  final bool hasUnsavedChanges;
  final List<SamplePack> samplePacks;
  final List<String> soundfonts;

  MusicStudioState copyWith({
    String? projectName,
    List<Track>? tracks,
    int? selectedTrackIndex,
    bool? isPlaying,
    bool? isRecording,
    int? currentStep,
    int? bpm,
    int? stepsPerBar,
    bool? hasUnsavedChanges,
    List<SamplePack>? samplePacks,
    List<String>? soundfonts,
  }) {
    return MusicStudioState(
      projectName: projectName ?? this.projectName,
      tracks: tracks ?? this.tracks,
      selectedTrackIndex: selectedTrackIndex ?? this.selectedTrackIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isRecording: isRecording ?? this.isRecording,
      currentStep: currentStep ?? this.currentStep,
      bpm: bpm ?? this.bpm,
      stepsPerBar: stepsPerBar ?? this.stepsPerBar,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      samplePacks: samplePacks ?? this.samplePacks,
      soundfonts: soundfonts ?? this.soundfonts,
    );
  }

  @override
  List<Object?> get props => [
        tracks,
        selectedTrackIndex,
        isPlaying,
        isRecording,
        currentStep,
        bpm,
        stepsPerBar,
        projectName,
        hasUnsavedChanges,
        samplePacks,
        soundfonts,
      ];

  @override
  String toString() {
    return 'MusicStudioState(projectName: $projectName, tracks: $tracks, selectedTrackIndex: $selectedTrackIndex, isPlaying: $isPlaying, isRecording: $isRecording, currentStep: $currentStep, bpm: $bpm, stepsPerBar: $stepsPerBar, hasUnsavedChanges: $hasUnsavedChanges, samplePacks: $samplePacks, soundfonts: $soundfonts)';
  }
}