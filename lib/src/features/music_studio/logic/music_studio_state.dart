import 'package:equatable/equatable.dart';
import 'package:mstudio/src/features/music_studio/models/sample_pack.dart';

import '../models/track.dart';

class MusicStudioState extends Equatable {
  const MusicStudioState({
    this.tracks = const [],
    this.soundfonts = const [],
    this.samplePacks = const [],
    this.isPlaying = false,
    this.isRecording = false,
    this.currentStep = 0,
    this.bpm = 120,
    this.bars = 2,
    this.stepsPerBar = 48,
    this.selectedTrackIndex = 0,
    this.projectName = 'Untitled Project',
    this.hasUnsavedChanges = false,
    this.isLooping = false,
    this.isMetronomeEnabled = false,
  });

  final List<Track> tracks;
  final int selectedTrackIndex;
  final bool isPlaying;
  final bool isRecording;
  final int currentStep;
  final int bpm;
  final int stepsPerBar;
  final int bars;
  final String projectName;
  final bool hasUnsavedChanges;
  final List<SamplePack> samplePacks;
  final List<String> soundfonts;
  final bool isLooping;
  final bool isMetronomeEnabled;

  MusicStudioState copyWith({
    String? projectName,
    List<Track>? tracks,
    int? selectedTrackIndex,
    bool? isPlaying,
    bool? isRecording,
    int? currentStep,
    int? bpm,
    int? stepsPerBar,
    int? bars,
    bool? hasUnsavedChanges,
    List<SamplePack>? samplePacks,
    List<String>? soundfonts,
    bool? isLooping,
    bool? isMetronomeEnabled,
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
      bars: bars ?? this.bars,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      samplePacks: samplePacks ?? this.samplePacks,
      soundfonts: soundfonts ?? this.soundfonts,
      isLooping: isLooping ?? this.isLooping,
      isMetronomeEnabled: isMetronomeEnabled ?? this.isMetronomeEnabled,
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
        bars,
        projectName,
        hasUnsavedChanges,
        samplePacks,
        soundfonts,
        isLooping,
        isMetronomeEnabled,
      ];

  @override
  String toString() {
    return 'MusicStudioState(projectName: $projectName, tracks: $tracks, selectedTrackIndex: $selectedTrackIndex, isPlaying: $isPlaying, isRecording: $isRecording, currentStep: $currentStep, bpm: $bpm, stepsPerBar: $stepsPerBar, bars: $bars, hasUnsavedChanges: $hasUnsavedChanges, samplePacks: $samplePacks, soundfonts: $soundfonts, isLooping: $isLooping, isMetronomeEnabled: $isMetronomeEnabled)';
  }
}