import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mstudio/src/features/music_studio/models/sample_pack.dart';

import '../../../shared/services/audio_service.dart';

import 'dart:math';

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
    await _loadInstruments();
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

      _trackRepository.updateTracks(currentTracks);
      _updateAudioServiceLoopLength();

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

        _trackRepository.updateTracks(tracks);
        _updateAudioServiceLoopLength();
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

      _trackRepository.updateTracks(tracks);
      _updateAudioServiceLoopLength();
      value = value.copyWith(hasUnsavedChanges: true);
    }
  }

  void deleteNote(String noteId) {
    final tracks = value.tracks;
    for (final track in tracks) {
      final note = track.notes.firstWhereOrNull((n) => n.id == noteId);
      if (note != null) {
        removeNote(note);
        return; // Assume note IDs are unique across all tracks
      }
    }
  }

  void updateMultipleNotes(List<Note> notesToUpdate) {
    if (notesToUpdate.isEmpty) return;

    final tracks = List<Track>.from(value.tracks);
    bool changed = false;

    // Group notes by track index for efficiency
    final notesByTrack = groupBy(notesToUpdate, (note) => note.trackIndex);

    notesByTrack.forEach((trackIndex, notes) {
      if (trackIndex >= 0 && trackIndex < tracks.length) {
        final track = tracks[trackIndex];
        final updatedNotes = List<Note>.from(track.notes);

        for (var updatedNote in notes) {
          final noteIndex = updatedNotes.indexWhere((n) => n.id == updatedNote.id);
          if (noteIndex != -1) {
            updatedNotes[noteIndex] = updatedNote;
            changed = true;
          }
        }
        tracks[trackIndex] = track.copyWith(notes: updatedNotes);
      }
    });

    if (changed) {
      _trackRepository.updateTracks(tracks);
      _updateAudioServiceLoopLength();
      value = value.copyWith(hasUnsavedChanges: true);
    }
  }

  void deleteMultipleNotes(List<String> noteIds) {
    if (noteIds.isEmpty) return;

    final tracks = List<Track>.from(value.tracks);
    bool changed = false;

    // Create a map of noteId to trackIndex for quick lookup
    final Map<String, int> noteIdToTrackIndex = {};
    for (int i = 0; i < tracks.length; i++) {
      for (var note in tracks[i].notes) {
        noteIdToTrackIndex[note.id] = i;
      }
    }

    final notesToDeleteByTrack = <int, List<String>>{};
    for (var noteId in noteIds) {
      if (noteIdToTrackIndex.containsKey(noteId)) {
        final trackIndex = noteIdToTrackIndex[noteId]!;
        if (!notesToDeleteByTrack.containsKey(trackIndex)) {
          notesToDeleteByTrack[trackIndex] = [];
        }
        notesToDeleteByTrack[trackIndex]!.add(noteId);
      }
    }

    notesToDeleteByTrack.forEach((trackIndex, ids) {
      final track = tracks[trackIndex];
      final updatedNotes =
          track.notes.where((n) => !ids.contains(n.id)).toList();
      tracks[trackIndex] = track.copyWith(notes: updatedNotes);
      changed = true;
    });

    if (changed) {
      _trackRepository.updateTracks(tracks);
      _updateAudioServiceLoopLength();
      value = value.copyWith(hasUnsavedChanges: true);
    }
  }

  Future<void> _loadDefaultTracks() async {
    final defaultTracks = [
      Track(
        id: 'piano',
        name: 'Piano',
        color: const Color(0xFF9C27B0), // Purple
        samplePath: 'assets/soundfonts/Piano.sf2',
        audioSourceType: AudioSourceType.soundfont,
        steps:
            List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
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

  Future<void> _loadInstruments() async {
    // Load soundfonts from assets
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final soundfontPaths = manifestMap.keys
        .where((String key) => key.startsWith('assets/soundfonts/'))
        .toList();

    final sampleAssets = manifestMap.keys
        .where((String key) => key.startsWith('assets/samples/'))
        .toList();

    final Map<String, List<String>> packsData = {};
    for (var asset in sampleAssets) {
      final parts = asset.split('/');
      if (parts.length > 3) { // assets/samples/PACK_NAME/sample.wav
        final packName = parts[2];
        if (!packsData.containsKey(packName)) {
          packsData[packName] = [];
        }
        packsData[packName]!.add(asset);
      }
    }

    final samplePacks = packsData.entries.map((entry) {
      final packName = entry.key;
      final packPath = 'assets/samples/$packName';
      final samples = entry.value.map((path) {
        final fileName = path.split('/').last;
        return Sample(
          name: fileName.split('.').first,
          path: path,
        );
      }).toList();

      return SamplePack(
        id: packName,
        name: packName,
        path: packPath,
        samples: samples,
      );
    }).toList();

    value = value.copyWith(soundfonts: soundfontPaths, samplePacks: samplePacks);
  }

  // Transport controls
  void play() {
    final totalSteps = _calculateTotalSteps();
    _audioService.play(totalSteps: totalSteps);
  }

  void stop() {
    _audioService.stop();
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

  void setBars(int bars) {
    if (bars > 0) {
      value = value.copyWith(bars: bars, hasUnsavedChanges: true);
    }
  }

  void seekToStep(int step) {
    _audioService.seekToStep(step);
  }

  int _calculateTotalSteps() {
    int lastStep = 0;
    for (final track in value.tracks) {
      if (track.notes.isNotEmpty) {
        final maxEndStep =
            track.notes.map((n) => n.step + n.duration).reduce(max);
        if (maxEndStep > lastStep) {
          lastStep = maxEndStep;
        }
      }
    }

    int barsNeeded = 1;
    if (lastStep > 0) {
      barsNeeded = (lastStep / value.stepsPerBar).ceil();
    }

    if (barsNeeded == 0) {
      barsNeeded = 1;
    }

    return barsNeeded * value.stepsPerBar;
  }

  void _updateAudioServiceLoopLength() {
    final totalSteps = _calculateTotalSteps();
    _audioService.updateLoopLength(totalSteps);
  }

  // Track management
  void addTrackFromInstrument(Map<String, dynamic> instrument) {
    final String name = instrument['name'];
    final String? path = instrument['path'];
    final String type = instrument['type'];

    AudioSourceType audioSourceType;
    switch (type) {
      case 'soundfont':
        audioSourceType = AudioSourceType.soundfont;
        break;
      case 'sample':
        // Assuming samples from assets are treated as device files for now
        audioSourceType = AudioSourceType.deviceFile;
        break;
      default: // 'synth' or other types
        audioSourceType = AudioSourceType.asset; // Placeholder for synth
    }

    final colors = [
      const Color(0xFFF44336),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFFEB3B),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF00BCD4),
      const Color(0xFF8BC34A),
    ];

    final int? baseMidiNote = instrument['baseMidiNote'];

    final newTrack = Track(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: colors[value.tracks.length % colors.length],
      steps: List.generate(16, (_) => const SequencerStep(isActive: false)),
      samplePath: path,
      audioSourceType: audioSourceType,
      baseMidiNoteForSample: baseMidiNote,
    );

    final updatedTracks = [...value.tracks, newTrack];
    value = value.copyWith(
      tracks: updatedTracks,
      hasUnsavedChanges: true,
    );

    if (path != null) {
      _audioService.loadTrackSample(newTrack.id, path, audioSourceType);
    }
  }

  void addTrackWithSample(String name, String samplePath) {
    final instrument = {
      'name': name,
      'path': samplePath,
      'type': 'sample',
    };
    addTrackFromInstrument(instrument);
  }

  void updateTrackInstrument(int index, Map<String, dynamic> instrument) {
    if (index < 0 || index >= value.tracks.length) return;

    final String? path = instrument['path'];
    final String type = instrument['type'];

    AudioSourceType audioSourceType;
    switch (type) {
      case 'soundfont':
        audioSourceType = AudioSourceType.soundfont;
        break;
      case 'sample':
        audioSourceType = AudioSourceType.deviceFile;
        break;
      default: // 'synth' or other types
        audioSourceType = AudioSourceType.asset; // Placeholder
    }

    final int? baseMidiNote = instrument['baseMidiNote'];

    final updatedTracks = [...value.tracks];
    final oldTrack = updatedTracks[index];
    updatedTracks[index] = oldTrack.copyWith(
      samplePath: path,
      audioSourceType: audioSourceType,
      baseMidiNoteForSample: baseMidiNote,
    );

    value = value.copyWith(
      tracks: updatedTracks,
      hasUnsavedChanges: true,
    );

    if (path != null) {
      _audioService.loadTrackSample(oldTrack.id, path, audioSourceType);
    }
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
