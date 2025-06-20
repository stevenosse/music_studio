import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:mstudio/src/shared/services/app_logger.dart';
import '../../features/music_studio/models/track.dart';
import '../../features/music_studio/repositories/track_repository.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final MidiPro _midiPro = MidiPro();
  int? _soundfontId;

  // Repository for track data
  final TrackRepository _trackRepository = TrackRepository();

  // Audio players for sample playback
  final Map<String, List<AudioPlayer>> _audioPlayers = {};
  final Map<String, String> _trackSamplePaths = {};
  final Map<String, AudioSourceType> _trackSourceTypes = {};
  final Map<String, int> _playerIndexes = {};

  Timer? _sequencerTimer;
  bool _isPlaying = false;
  bool _isRecording = false;
  int _currentStep = 0;
  int _bpm = 120;
  final int _stepsPerBar = 32;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isRecording => _isRecording;
  bool get isLooping => true; // Always loop
  int get currentStep => _currentStep;
  int get bpm => _bpm;
  int get stepsPerBar => _stepsPerBar;
  TrackRepository get trackRepository => _trackRepository;

  // Step duration in milliseconds - for 16 steps per bar (16th note resolution)
  // This gives us 32 steps across 2 bars, maintaining the original tempo feel
  int get stepDuration => (60000 / (_bpm * 4)).round();

  final ValueNotifier<int> currentStepNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isRecordingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> bpmNotifier = ValueNotifier<int>(120);

  Future<void> initialize() async {
    // Initialize MIDI Pro
    try {
      await loadSoundfont('assets/soundfonts/Piano.sf2');
      debugPrint('Soundfont loaded successfully');
    } catch (e) {
      debugPrint('Failed to load soundfont: $e');
    }
  }

  Future<void> loadTrackSample(
      String trackId, String samplePath, AudioSourceType sourceType) async {
    try {
      // Store the sample path and source type for this track
      _trackSamplePaths[trackId] = samplePath;
      _trackSourceTypes[trackId] = sourceType;

      // Create multiple audio players for this track to allow overlapping sounds
      if (!_audioPlayers.containsKey(trackId)) {
        _audioPlayers[trackId] = List.generate(4, (_) => AudioPlayer());
        _playerIndexes[trackId] = 0;
      }

      debugPrint(
          'Track $trackId configured with sample: $samplePath (${sourceType.name})');
    } catch (e) {
      debugPrint('Failed to configure track $trackId: $e');
    }
  }

  Future<void> playTrackSample(String trackId, {int? pitch, double volume = 1.0}) async {
    const int defaultBaseMidiNote = 60; // C4 - assuming samples are pitched at C4 by default
    double playbackRate = 1.0;

    if (pitch != null) {
      playbackRate = math.pow(2, (pitch - defaultBaseMidiNote) / 12.0).toDouble();
    }
    try {
      final samplePath = _trackSamplePaths[trackId];
      final sourceType = _trackSourceTypes[trackId];
      final players = _audioPlayers[trackId];

      if (samplePath != null && players != null && sourceType != null) {
        // Use round-robin to select next available player
        final currentIndex = _playerIndexes[trackId] ?? 0;
        final player = players[currentIndex];
        _playerIndexes[trackId] = (currentIndex + 1) % players.length;

        // Play audio sample based on source type
        await player.setVolume(volume);
        await player.setPlaybackRate(playbackRate);
        switch (sourceType) {
          case AudioSourceType.asset:
            await player
                .play(AssetSource(samplePath.replaceFirst('assets/', '')));
            break;
          case AudioSourceType.deviceFile:
            await player.play(DeviceFileSource(samplePath));
            break;
        }
        debugPrint(
            'Playing sample $samplePath for track $trackId with volume $volume (player ${currentIndex + 1})');
      } else { // Something is missing for sample playback OR it's a MIDI track
        if (samplePath == null) {
          // This is a track that's intended to be MIDI (or has no sample assigned)
          AppLogger().debug('No sample path for track $trackId. Playing default MIDI note.');
          await playNote(defaultBaseMidiNote, (volume * 127).round());
          debugPrint('Playing MIDI note for track $trackId with volume $volume.'); // Log MIDI play
        } else {
          // This means samplePath is NOT null, but players or sourceType is missing for this track in AudioService.
          // This is an improperly configured sample track within AudioService's state.
          AppLogger().warning('Track $trackId ($samplePath) has a sample path but is not properly initialized in AudioService (missing players or sourceType). Cannot play sample. Desired rate: $playbackRate, volume: $volume.');
          // Do not play MIDI as a fallback here, and do not log as if playing MIDI.
        }
      }
    } catch (e) {
      debugPrint('Failed to play track $trackId: $e');
    }
  }

  Future<void> loadSoundfont(String path) async {
    try {
      _soundfontId =
          await _midiPro.loadSoundfont(path: path, bank: 0, program: 0);
      AppLogger().info('Soundfont loaded successfully with ID: $_soundfontId');
    } catch (e) {
      AppLogger().error('Error loading soundfont: $e');
    }
  }

  Future<void> playNote(int midiNote, int velocity) async {
    try {
      await _midiPro.playNote(
        sfId: _soundfontId ?? 1,
        channel: 0,
        key: midiNote,
        velocity: velocity,
      );
    } catch (e) {
      AppLogger().error('Error playing note: $e');
    }
  }

  Future<void> playPreviewNote({required int pitch, required String trackId, required int velocity}) async {
    final samplePath = _trackSamplePaths[trackId];
    if (samplePath != null) {
      // It's a sample-based track, play with pitch shifting
      AppLogger().debug('Previewing sample for track $trackId: pitch $pitch, velocity $velocity');
      await playTrackSample(trackId, pitch: pitch, volume: velocity / 127.0);
    } else {
      // It's a MIDI/soundfont track
      AppLogger().debug('Previewing MIDI note for track $trackId: pitch $pitch, velocity $velocity');
      try {
        await _midiPro.playNote(
          sfId: _soundfontId ?? 1, // Use loaded soundfont ID
          channel: 0, // Default MIDI channel
          key: pitch,
          velocity: velocity.clamp(0, 127),
        );
      } catch (e) {
        AppLogger().error('Error playing preview note: $e');
      }
    }
  }

  Future<void> stopNote(int midiNote) async {
    try {
      await _midiPro.stopNote(
        sfId: _soundfontId ?? 1,
        channel: 0,
        key: midiNote,
      );
    } catch (e) {
      AppLogger().error('Error stopping note: $e');
    }
  }

  void play() {
    if (_isPlaying) return;

    _isPlaying = true;
    isPlayingNotifier.value = true;

    _startSequencer();
  }

  // No longer needed as we use the repository

  Future<void> stop() async {
    _sequencerTimer?.cancel();
    _sequencerTimer = null;
    _isPlaying = false;
    _currentStep = 0;

    isPlayingNotifier.value = false;
    currentStepNotifier.value = 0;
  }

  Future<void> pause() async {
    _sequencerTimer?.cancel();
    _sequencerTimer = null;
    _isPlaying = false;
    isPlayingNotifier.value = false;
  }

  void record() {
    _isRecording = !_isRecording;
    isRecordingNotifier.value = _isRecording;
  }

  void setBpm(int newBpm) {
    if (newBpm >= 60 && newBpm <= 200) {
      _bpm = newBpm;
      bpmNotifier.value = newBpm;

      // Restart timer with new tempo if playing
      if (_isPlaying) {
        _sequencerTimer?.cancel();
        _startSequencer();
      }
    }
  }

  void seekToStep(int step) {
    if (step >= 0 && step < _stepsPerBar) {
      _currentStep = step;
      currentStepNotifier.value = _currentStep;
    }
  }

  void _startSequencer() {
    _sequencerTimer = Timer.periodic(
      Duration(milliseconds: stepDuration),
      (timer) => _onSequencerTick(),
    );
  }

  void _onSequencerTick() {
    final tracks = _trackRepository.tracks;
    
    // Play active steps for each track first to minimize latency
    for (final track in tracks) {
      if (!track.isMuted && _currentStep < track.steps.length) {
        final step = track.steps[_currentStep];
        if (step.isActive) {
          playTrackSample(
            track.id,
            volume: track.volume * step.velocity,
          );
        }

        // Also play any notes at this step for piano roll tracks
        for (final note in track.notes) {
          if (note.step == _currentStep) {
            if (track.samplePath != null) {
              playTrackSample(
                track.id,
                pitch: note.pitch, // Add pitch here
                volume: track.volume * (note.velocity / 127.0),
              );
            } else {
              playNote(note.pitch, note.velocity);
            }
          }
        }
      }
    }

    // Update UI after audio playback
    currentStepNotifier.value = _currentStep;

    _currentStep++;

    // Always loop back to start if at end
    if (_currentStep >= _stepsPerBar) {
      _currentStep = 0;
    }
  }

  Future<void> dispose() async {
    _sequencerTimer?.cancel();

    // Dispose all audio players
    for (final players in _audioPlayers.values) {
      for (final player in players) {
        await player.dispose();
      }
    }
    _audioPlayers.clear();
    _trackSamplePaths.clear();
    _trackSourceTypes.clear();
    _playerIndexes.clear();

    // flutter_midi_pro handles cleanup automatically

    currentStepNotifier.dispose();
    isPlayingNotifier.dispose();
    isRecordingNotifier.dispose();
    bpmNotifier.dispose();
  }
}
