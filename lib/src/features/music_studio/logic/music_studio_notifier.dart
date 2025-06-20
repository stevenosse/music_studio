import 'dart:async';

import '../../../shared/services/audio_service.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mstudio/gen/assets.gen.dart';
import '../models/track.dart';
import '../models/sequencer_step.dart';
import '../models/note.dart';
import '../repositories/track_repository.dart';
import 'music_studio_state.dart';

class MusicStudioNotifier extends ValueNotifier<MusicStudioState> {
  MusicStudioNotifier() : super(const MusicStudioState()) {
    _initialize();
  }

  final AudioService _audioService = AudioService();
  final TrackRepository _trackRepository = TrackRepository();

  AudioService get audioService => _audioService;
  TrackRepository get trackRepository => _trackRepository;

  bool get isPlaying => value.isPlaying;

  Future<void> _initialize() async {
    await _audioService.initialize();
    _setupAudioListeners();
    _setupTrackRepositoryListeners();
    await _loadDefaultTracks();
  }

  void _setupAudioListeners() {
    _audioService.isPlayingNotifier.addListener(() {
      value = value.copyWith(isPlaying: _audioService.isPlaying);
    });

    _audioService.isRecordingNotifier.addListener(() {
      value = value.copyWith(isRecording: _audioService.isRecording);
    });

    _audioService.currentStepNotifier.addListener(() {
      value = value.copyWith(currentStep: _audioService.currentStep);
    });

    _audioService.bpmNotifier.addListener(() {
      value = value.copyWith(bpm: _audioService.bpm);
    });
  }

  void _setupTrackRepositoryListeners() {
    _trackRepository.tracksNotifier.addListener(() {
      final newTracksFromRepo = _trackRepository.tracks;
      value = value.copyWith(tracks: newTracksFromRepo);
    });
  }

  void addNote(Note note) {
    final List<Track> currentTracks = List<Track>.from(value.tracks);
    final trackIndex = note.trackIndex;

    if (trackIndex >= 0 && trackIndex < currentTracks.length) {
      final Track targetTrack = currentTracks[trackIndex];
      final List<Note> updatedNotes = List<Note>.from(targetTrack.notes);

      final existingNoteIndex = updatedNotes
          .indexWhere((n) => n.step == note.step && n.pitch == note.pitch);

      if (existingNoteIndex != -1) {
        return;
      } else {
        updatedNotes.add(note);
      }

      final Track updatedTrack = targetTrack.copyWith(notes: updatedNotes);
      currentTracks[trackIndex] = updatedTrack;

      // Update the repository. The listener will handle updating `value.tracks`.
      _trackRepository.updateTracks(currentTracks);

      // Update other parts of the state if necessary, like 'hasUnsavedChanges'.
      // The tracks themselves will be updated via the repository listener.
      if (!value.hasUnsavedChanges) {
        value = value.copyWith(hasUnsavedChanges: true);
      }
    }
  }

  void updateNote(Note updatedNote) {
    final tracks = List<Track>.from(value.tracks);
    final trackIndex = updatedNote.trackIndex;
    if (trackIndex >= 0 && trackIndex < tracks.length) {
      final track = tracks[trackIndex];
      final noteIndex = track.notes.indexWhere((n) => n.id == updatedNote.id);
      if (noteIndex != -1) {
        final updatedNotes = List<Note>.from(track.notes);
        updatedNotes[noteIndex] = updatedNote;
        tracks[trackIndex] = track.copyWith(notes: updatedNotes);

        // Update repository instead of directly updating audio service
        _trackRepository.updateTracks(tracks);
        value = value.copyWith(hasUnsavedChanges: true);
      }
    }
  }

  Note? getNoteAt(int trackIndex, int step) {
    if (trackIndex >= 0 && trackIndex < value.tracks.length) {
      final track = value.tracks[trackIndex];
      try {
        return track.notes.firstWhereOrNull((note) => note.step == step);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void removeNote(Note note) {
    final tracks = List<Track>.from(value.tracks);
    final trackIndex = note.trackIndex;

    if (trackIndex >= 0 && trackIndex < tracks.length) {
      final track = tracks[trackIndex];

      final updatedNotes = track.notes.where((n) => n.id != note.id).toList();

      tracks[trackIndex] = track.copyWith(notes: updatedNotes);

      // Update repository instead of directly updating audio service
      _trackRepository.updateTracks(tracks);
      value = value.copyWith(hasUnsavedChanges: true);
    }
  }

  Future<void> _loadDefaultTracks() async {
    final defaultTracks = [
      Track(
        id: 'kick',
        name: 'Kick',
        color: const Color(0xFF2196F3),
        samplePath: Assets.samples.aSAINT6RonnyKick,
        steps:
            List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
      Track(
        id: 'snare',
        name: 'Snare',
        color: const Color(0xFFFF5722),
        samplePath: Assets.samples.aSAINT6PopSnare1,
        steps:
            List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
      Track(
        id: 'clap',
        name: 'Clap',
        color: const Color(0xFF4CAF50),
        samplePath: Assets.samples.aSAINT6BounceClap,
        steps:
            List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
      Track(
        id: 'hihat',
        name: 'Hi-hat',
        color: const Color(0xFFFFEB3B),
        samplePath: Assets.samples.aSAINT6808HiHat1,
        steps:
            List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
    ];

    for (final track in defaultTracks) {
      if (track.samplePath != null) {
        await _audioService.loadTrackSample(
            track.id, track.samplePath!, track.audioSourceType);
      }
    }

    // Update repository with default tracks
    _trackRepository.updateTracks(defaultTracks);
    value = value.copyWith(tracks: defaultTracks);
  }

  // Transport controls
  void play() {
    _audioService.play();
  }

  Future<void> stop() async {
    await _audioService.stop();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  void record() {
    _audioService.record();
  }

  void setBpm(int bpm) {
    _audioService.setBpm(bpm);
  }

  // Track management
  void addTrack() {
    final newTrack = Track(
      id: 'track_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Track ${value.tracks.length + 1}',
      color: const Color(0xFF9C27B0),
      samplePath: 'audio/samples/kick.wav', // Default sample
      steps: List.generate(
          value.stepsPerBar, (index) => const SequencerStep(isActive: false)),
    );

    final updatedTracks = [...value.tracks, newTrack];
    value = value.copyWith(
      tracks: updatedTracks,
      hasUnsavedChanges: true,
    );

    if (newTrack.samplePath != null) {
      _audioService.loadTrackSample(
          newTrack.id, newTrack.samplePath!, newTrack.audioSourceType);
    }
  }

  void addTrackWithSample(String name, String samplePath) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFFFF5722),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFF8BC34A),
    ];

    final newTrack = Track(
      id: 'track_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      color: colors[value.tracks.length % colors.length],
      samplePath: samplePath,
      steps: List.generate(
          value.stepsPerBar, (index) => const SequencerStep(isActive: false)),
    );

    final updatedTracks = [...value.tracks, newTrack];
    value = value.copyWith(
      tracks: updatedTracks,
      hasUnsavedChanges: true,
    );

    _audioService.loadTrackSample(
        newTrack.id, samplePath, AudioSourceType.deviceFile);
  }

  void removeTrack(int index) {
    if (index >= 0 && index < value.tracks.length) {
      final updatedTracks = [...value.tracks];
      updatedTracks.removeAt(index);

      int newSelectedIndex = value.selectedTrackIndex;
      if (newSelectedIndex >= updatedTracks.length) {
        newSelectedIndex = updatedTracks.length - 1;
      }
      if (newSelectedIndex < 0) newSelectedIndex = 0;

      value = value.copyWith(
        tracks: updatedTracks,
        selectedTrackIndex: newSelectedIndex,
        hasUnsavedChanges: true,
      );
    }
  }

  void selectTrack(int index) {
    if (index >= 0 && index < value.tracks.length) {
      value = value.copyWith(selectedTrackIndex: index);
    }
  }

  void updateTrackName(int index, String name) {
    if (index >= 0 && index < value.tracks.length) {
      final updatedTracks = [...value.tracks];
      updatedTracks[index] = updatedTracks[index].copyWith(name: name);
      value = value.copyWith(
        tracks: updatedTracks,
        hasUnsavedChanges: true,
      );
    }
  }

  void toggleTrackMute(int index) {
    if (index >= 0 && index < value.tracks.length) {
      final updatedTracks = [...value.tracks];
      updatedTracks[index] = updatedTracks[index].copyWith(
        isMuted: !updatedTracks[index].isMuted,
      );
      value = value.copyWith(
        tracks: updatedTracks,
        hasUnsavedChanges: true,
      );
    }
  }

  void toggleTrackSolo(int index) {
    if (index >= 0 && index < value.tracks.length) {
      final updatedTracks = [...value.tracks];
      updatedTracks[index] = updatedTracks[index].copyWith(
        isSolo: !updatedTracks[index].isSolo,
      );
      value = value.copyWith(
        tracks: updatedTracks,
        hasUnsavedChanges: true,
      );
    }
  }

  void setTrackVolume(int index, double volume) {
    if (index >= 0 && index < value.tracks.length) {
      final updatedTracks = [...value.tracks];
      updatedTracks[index] = updatedTracks[index].copyWith(volume: volume);

      // Update repository
      _trackRepository.updateTracks(updatedTracks);
      value = value.copyWith(hasUnsavedChanges: true);
    }
  }

  void toggleStep(int trackIndex, int stepIndex) {
    final note = getNoteAt(trackIndex, stepIndex);
    if (note != null) {
      removeNote(note);
    } else {
      final track = value.tracks[trackIndex];
      final newNote = Note(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        pitch: 72, // Default to C5
        step: stepIndex,
        trackIndex: trackIndex,
        color: track.color,
      );
      addNote(newNote);
    }
  }

  void setStepVelocity(int trackIndex, int stepIndex, int velocity) {
    if (trackIndex >= 0 && trackIndex < value.tracks.length) {
      final track = value.tracks[trackIndex];
      if (stepIndex >= 0 && stepIndex < track.steps.length) {
        final updatedSteps = [...track.steps];
        updatedSteps[stepIndex] = updatedSteps[stepIndex].copyWith(
          velocity: velocity.clamp(0, 127).toDouble(),
        );

        final updatedTracks = [...value.tracks];
        updatedTracks[trackIndex] = track.copyWith(steps: updatedSteps);

        value = value.copyWith(
          tracks: updatedTracks,
          hasUnsavedChanges: true,
        );
      }
    }
  }

  Future<void> saveProject() async {
    try {
      // Use repository to save tracks
      await _trackRepository.saveTracks(
        value.projectName,
        value.bpm,
        value.stepsPerBar,
      );
      value = value.copyWith(hasUnsavedChanges: false);
    } catch (e) {
      debugPrint('Failed to save project: $e');
    }
  }

  Future<void> loadProject() async {
    try {
      // Use repository to load tracks
      final projectData = await _trackRepository.loadTracks();
      final tracks = projectData['tracks'] as List<Track>;

      for (final track in tracks) {
        if (track.samplePath != null) {
          await _audioService.loadTrackSample(
              track.id, track.samplePath!, track.audioSourceType);
        }
      }

      value = value.copyWith(
        projectName: projectData['projectName'] as String,
        bpm: projectData['bpm'] as int,
        stepsPerBar: projectData['stepsPerBar'] as int,
        hasUnsavedChanges: false,
      );

      _audioService.setBpm(value.bpm);
    } catch (e) {
      debugPrint('Failed to load project: $e');
    }
  }

  Future<void> previewNote(int pitch, int trackIndex) async {
    if (trackIndex >= 0 && trackIndex < value.tracks.length) {
      final track = value.tracks[trackIndex];
      // Assuming a default velocity for preview
      // We'll add playPreviewNote to AudioService next.
      await _audioService.playPreviewNote(pitch: pitch, trackId: track.id, velocity: 100);
    } else {
      debugPrint('PreviewNote: Invalid trackIndex: $trackIndex');
    }
  }

  Future<void> newProject() async {
    stop();
    value = const MusicStudioState();
    await _loadDefaultTracks();
  }

  @override
  void dispose() {
    _audioService.dispose().ignore();
    super.dispose();
  }
}
