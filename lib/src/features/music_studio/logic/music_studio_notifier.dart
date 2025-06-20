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

      final existingNoteIndex = updatedNotes.indexWhere((n) => n.step == note.step && n.pitch == note.pitch);

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
      final updatedNotes = track.notes.where((n) => !ids.contains(n.id)).toList();
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
        steps: List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
      Track(
        id: 'kick',
        name: 'Kick',
        color: const Color(0xFF2196F3),
        samplePath: Assets.samples.aSAINT6RonnyKick,
        steps: List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
      Track(
        id: 'snare',
        name: 'Snare',
        color: const Color(0xFFFF5722),
        samplePath: Assets.samples.aSAINT6PopSnare1,
        steps: List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
      Track(
        id: 'clap',
        name: 'Clap',
        color: const Color(0xFF4CAF50),
        samplePath: Assets.samples.aSAINT6BounceClap,
        steps: List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
      Track(
        id: 'hihat',
        name: 'Hi-hat',
        color: const Color(0xFFFFEB3B),
        samplePath: Assets.samples.aSAINT6808HiHat1,
        steps: List.generate(32, (index) => const SequencerStep(isActive: false)),
      ),
    ];

    for (final track in defaultTracks) {
      if (track.samplePath != null) {
        await _audioService.loadTrackSample(track.id, track.samplePath!, track.audioSourceType);
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

    final soundfontPaths = manifestMap.keys.where((String key) => key.startsWith('assets/soundfonts/')).toList();

    final sampleAssets = manifestMap.keys.where((String key) => key.startsWith('assets/samples/')).toList();

    final Map<String, List<String>> packsData = {};
    for (var asset in sampleAssets) {
      final parts = asset.split('/');
      if (parts.length > 3) {
        // assets/samples/PACK_NAME/sample.wav
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

  void toggleLooping() {
    final bool newLoopingState = !value.isLooping;
    value = value.copyWith(
      isLooping: newLoopingState,
      hasUnsavedChanges: true,
    );
    // If AudioService needs to be informed about looping state for playback:
    // _audioService.setLooping(newLoopingState);
  }

  void toggleMetronome() {
    final bool newMetronomeState = !value.isMetronomeEnabled;
    value = value.copyWith(
      isMetronomeEnabled: newMetronomeState,
      hasUnsavedChanges: true,
    );
    // If AudioService needs to be informed about metronome state:
    // _audioService.setMetronomeEnabled(newMetronomeState);
  }

  int _calculateTotalSteps() {
    int lastStep = 0;
    for (final track in value.tracks) {
      if (track.notes.isNotEmpty) {
        final maxEndStep = track.notes.map((n) => n.step + n.duration).reduce(max);
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
          await _audioService.loadTrackSample(track.id, track.samplePath!, track.audioSourceType);
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

  /// Loads a demo drill-style beat with 8 bars and trap/drill elements
  Future<void> loadDemoSong() async {
    // Clear any existing notes first
    final tracks = List<Track>.from(value.tracks);
    for (int i = 0; i < tracks.length; i++) {
      tracks[i] = tracks[i].copyWith(notes: []);
    }
    _trackRepository.updateTracks(tracks);
    
    // Set BPM to 140 for a drill beat
    setBpm(140);
    
    // Set to 8 bars for a longer pattern
    setBars(8);
    
    // Define a dark D# minor chord progression for drill style
    // D#m9 | Bmaj7 | G#m11 | C#7b9 | D#m9 | Bmaj7 | G#m11 | C#7b9
    // Each chord will be 12 steps (1 bar) in length
    
    // Piano is track index 0
    final pianoTrackIndex = 0;
    final pianoColor = tracks[pianoTrackIndex].color;
    
    // Define MIDI note numbers
    // C = 48, C# = 49, D = 50, D# = 51, E = 52, F = 53, F# = 54, G = 55, G# = 56, A = 57, A# = 58, B = 59
    // Add 12 for each octave up, subtract 12 for each octave down
    
    // Define the chord voicings as specified
    final leftHandChords = [
      // Bar 1 - D#m9: D#2, A#2
      [27, 34], // D#2 = 27, A#2 = 34
      // Bar 2 - Bmaj7: B2, F#3
      [35, 42], // B2 = 35, F#3 = 42
      // Bar 3 - G#m11: G#2, D#3
      [32, 39], // G#2 = 32, D#3 = 39
      // Bar 4 - C#7b9: C#2, G#2
      [25, 32], // C#2 = 25, G#2 = 32
      // Repeat for bars 5-8
      [27, 34], // D#m9
      [35, 42], // Bmaj7
      [32, 39], // G#m11
      [25, 32], // C#7b9
    ];
    
    final rightHandChords = [
      // Bar 1 - D#m9: F#4, A#4, C#5, F5
      [66, 70, 73, 77], // F#4 = 66, A#4 = 70, C#5 = 73, F5 = 77
      // Bar 2 - Bmaj7: A#3, D#4, F#4, A#4
      [58, 63, 66, 70], // A#3 = 58, D#4 = 63, F#4 = 66, A#4 = 70
      // Bar 3 - G#m11: B3, D#4, F#4, A#4
      [59, 63, 66, 70], // B3 = 59, D#4 = 63, F#4 = 66, A#4 = 70
      // Bar 4 - C#7b9: B3, D#4, F#4, A4
      [59, 63, 66, 69], // B3 = 59, D#4 = 63, F#4 = 66, A4 = 69
      // Repeat for bars 5-8
      [66, 70, 73, 77], // D#m9
      [58, 63, 66, 70], // Bmaj7
      [59, 63, 66, 70], // G#m11
      [59, 63, 66, 69], // C#7b9
    ];
    
    // Add all chords
    for (int bar = 0; bar < 8; bar++) {
      // Add left hand (bass) notes
      for (int i = 0; i < leftHandChords[bar].length; i++) {
        addNote(Note(
          id: 'lh_${bar}_$i',
          pitch: leftHandChords[bar][i],
          step: bar * 12,
          duration: 12,
          velocity: 110,
          trackIndex: pianoTrackIndex,
          color: pianoColor,
        ));
      }
      
      // Add right hand notes
      for (int i = 0; i < rightHandChords[bar].length; i++) {
        addNote(Note(
          id: 'rh_${bar}_$i',
          pitch: rightHandChords[bar][i],
          step: bar * 12,
          duration: 12,
          velocity: 95, // Slightly softer for the upper voicings
          trackIndex: pianoTrackIndex,
          color: pianoColor,
        ));
      }
    }
    
    // Add drill-style drum patterns based on the specified patterns
    
    // Kick drum (track index 1) - Punchy, syncopated pattern
    // Pattern: [X---X-------X--X-] (Hit on 1, 5, 12, 15)
    final kickTrackIndex = 1;
    final kickColor = tracks[kickTrackIndex].color;
    
    // Convert the pattern to step indices (0-based)
    // In a 16-step pattern: 0, 4, 11, 14 (zero-indexed)
    final kickSteps = [0, 4, 11, 14];
    
    for (int bar = 0; bar < 8; bar++) {
      for (final kickStep in kickSteps) {
        // Convert from 16-step pattern to 12-step bar
        // 16 steps in the pattern map to 12 steps in our sequencer
        final step = bar * 12 + ((kickStep * 12) ~/ 16);
        
        addNote(Note(
          id: 'kick_${bar}_$kickStep',
          pitch: 36, // Standard kick drum MIDI note
          step: step,
          duration: 1,
          velocity: 115, // Punchy kick
          trackIndex: kickTrackIndex,
          color: kickColor,
        ));
      }
    }
    
    // Snare drum (track index 2) - Classic Drill Snare on Beat 3
    // Pattern: [----X-------X---] (Hit on step 5 and 13)
    final snareTrackIndex = 2;
    final snareColor = tracks[snareTrackIndex].color;
    
    // Convert to 0-based indices: 4, 12
    final snareSteps = [4, 12];
    
    for (int bar = 0; bar < 8; bar++) {
      for (final snareStep in snareSteps) {
        // Convert from 16-step pattern to 12-step bar
        final step = bar * 12 + ((snareStep * 12) ~/ 16);
        
        addNote(Note(
          id: 'snare_${bar}_$snareStep',
          pitch: 38, // Snare drum
          step: step,
          duration: 1,
          velocity: 105, // Sharp snare
          trackIndex: snareTrackIndex,
          color: snareColor,
        ));
      }
      
      // Add rim shot variation on certain bars
      if (bar % 2 == 1) {
        final rimStep = bar * 12 + ((14 * 12) ~/ 16); // Step 14 in 16-step pattern
        addNote(Note(
          id: 'rim_${bar}_$rimStep',
          pitch: 37, // Rim shot
          step: rimStep,
          duration: 1,
          velocity: 85,
          trackIndex: snareTrackIndex,
          color: snareColor,
        ));
      }
    }
    
    // Hi-hat (track index 4) - Triplet drill bounce
    // Base pattern: [X---X---X---X---] with ghosted triplets
    final hihatTrackIndex = 4;
    final hihatColor = tracks[hihatTrackIndex].color;
    
    // Main hi-hat pattern (steps 0, 4, 8, 12 in 16-step pattern)
    final hihatMainSteps = [0, 4, 8, 12];
    
    // Triplet/ghost notes (steps 3, 5, 11 in 16-step pattern)
    final hihatTripletSteps = [3, 5, 11];
    
    for (int bar = 0; bar < 8; bar++) {
      // Add main hi-hat pattern
      for (final hihatStep in hihatMainSteps) {
        // Convert from 16-step pattern to 12-step bar
        final step = bar * 12 + ((hihatStep * 12) ~/ 16);
        
        addNote(Note(
          id: 'hihat_main_${bar}_$hihatStep',
          pitch: 42, // Closed hi-hat
          step: step,
          duration: 1,
          velocity: 100, // Accented
          trackIndex: hihatTrackIndex,
          color: hihatColor,
        ));
      }
      
      // Add triplet/ghost notes with lower velocity
      for (final tripletStep in hihatTripletSteps) {
        // Convert from 16-step pattern to 12-step bar
        final step = bar * 12 + ((tripletStep * 12) ~/ 16);
        
        addNote(Note(
          id: 'hihat_ghost_${bar}_$tripletStep',
          pitch: 42, // Closed hi-hat
          step: step,
          duration: 1,
          velocity: 60, // Ghosted/lower velocity
          trackIndex: hihatTrackIndex,
          color: hihatColor,
        ));
      }
      
      // Add triplet rolls on certain bars (bars 3, 7)
      if (bar == 3 || bar == 7) {
        // Add a triplet roll (3 quick hits)
        for (int i = 0; i < 3; i++) {
          final rollStep = bar * 12 + 9 + (i * 0.33).round(); // Around beat 3
          addNote(Note(
            id: 'hihat_roll_${bar}_$i',
            pitch: 42, // Closed hi-hat
            step: rollStep,
            duration: 1,
            velocity: 70 + (i * 5), // Increasing velocity
            trackIndex: hihatTrackIndex,
            color: hihatColor,
          ));
        }
      }
      
      // Add open hi-hats for variation
      if (bar % 4 == 2) {
        final openStep = bar * 12 + ((10 * 12) ~/ 16); // Step 10 in 16-step pattern
        addNote(Note(
          id: 'open_hihat_${bar}_$openStep',
          pitch: 46, // Open hi-hat
          step: openStep,
          duration: 1,
          velocity: 90,
          trackIndex: hihatTrackIndex,
          color: hihatColor,
        ));
      }
    }
    
    // Clap/Percussion (track index 3) - typical drill percussion
    final clapTrackIndex = 3;
    final clapColor = tracks[clapTrackIndex].color;
    
    // Add claps on specific beats
    for (int bar = 0; bar < 8; bar++) {
      // Standard claps reinforcing snares
      addNote(Note(
        id: 'clap_${bar}_1',
        pitch: 39, // Clap
        step: bar * 12 + 3,
        duration: 1,
        velocity: 90,
        trackIndex: clapTrackIndex,
        color: clapColor,
      ));
      
      addNote(Note(
        id: 'clap_${bar}_2',
        pitch: 39,
        step: bar * 12 + 9,
        duration: 1,
        velocity: 90,
        trackIndex: clapTrackIndex,
        color: clapColor,
      ));
      
      // Add percussion fills in bars 4 and 8
      if (bar == 3 || bar == 7) {
        for (int i = 0; i < 4; i++) {
          addNote(Note(
            id: 'perc_${bar}_$i',
            pitch: 67, // High percussion
            step: bar * 12 + 8 + i,
            duration: 1,
            velocity: 70 + (i * 5),
            trackIndex: clapTrackIndex,
            color: clapColor,
          ));
        }
      }
    }
    
    // Set project name
    value = value.copyWith(projectName: 'D# Minor Jazz-Drill - 140 BPM');
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
