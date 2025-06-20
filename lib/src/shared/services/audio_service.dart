import 'dart:async';
import 'dart:math' as math;
import 'package:collection/collection.dart';

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
  
  // Pre-loaded audio sources for reduced latency
  final Map<String, Source> _preloadedSources = {};

  Timer? _sequencerTimer;
  bool _isPlaying = false;
  bool _isRecording = false;
  int _currentStep = 0;
  int _bpm = 120;
  int _totalSteps = 32;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isRecording => _isRecording;
  bool get isLooping => true; // Always loop
  int get currentStep => _currentStep;
  int get bpm => _bpm;
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

      if (sourceType == AudioSourceType.soundfont) {
        await loadSoundfont(samplePath);
      } else {
        // Create multiple audio players for this track to allow overlapping sounds
        if (!_audioPlayers.containsKey(trackId)) {
          // Create players with low latency settings
          _audioPlayers[trackId] = List.generate(8, (_) {
            final player = AudioPlayer();
            // Set low latency mode where available
            player.setPlayerMode(PlayerMode.lowLatency);
            return player;
          });
          _playerIndexes[trackId] = 0;
          
          // Preload the audio source to reduce latency
          if (sourceType == AudioSourceType.asset) {
            _preloadedSources[trackId] = AssetSource(samplePath.replaceFirst('assets/', ''));
          } else if (sourceType == AudioSourceType.deviceFile) {
            _preloadedSources[trackId] = DeviceFileSource(samplePath);
          }
          
          // Pre-buffer audio for all players
          for (final player in _audioPlayers[trackId]!) {
            await player.setSource(_preloadedSources[trackId]!);
          }
        }
      }

      debugPrint(
          'Track $trackId configured with sample: $samplePath (${sourceType.name})');
    } catch (e) {
      debugPrint('Failed to configure track $trackId: $e');
    }
  }

  Future<void> playTrackSample(
      String trackId, {int? pitch, double volume = 1.0}) async {
    const int defaultBaseMidiNote = 60; // C4

    try {
      final sourceType = _trackSourceTypes[trackId];
      final track = _trackRepository.tracks.firstWhereOrNull((t) => t.id == trackId);

      if (sourceType == null || track == null) {
        AppLogger().warning(
            'Track $trackId has no source type or was not found, cannot be played.');
        return;
      }

      switch (sourceType) {
        case AudioSourceType.soundfont:
          if (pitch != null) {
            final velocity = (volume * 127).round().clamp(0, 127);
            await playNote(pitch, velocity);
          } else {
            AppLogger().info(
                'Soundfont track $trackId was triggered on a step with no note.');
          }
          break;
        case AudioSourceType.asset:
        case AudioSourceType.deviceFile:
          final players = _audioPlayers[trackId];

          if (players == null) {
            AppLogger().warning(
                'Track $trackId ($sourceType) is missing players.');
            return;
          }

          double playbackRate = 1.0;
          if (pitch != null) {
            final baseNote = track.baseMidiNoteForSample ?? defaultBaseMidiNote;
            playbackRate = math.pow(2, (pitch - baseNote) / 12.0).toDouble();
          }

          final currentIndex = _playerIndexes[trackId] ?? 0;
          final player = players[currentIndex];
          _playerIndexes[trackId] = (currentIndex + 1) % players.length;

          // Set volume and playback rate without awaiting to reduce latency
          player.setVolume(volume);
          player.setPlaybackRate(playbackRate);
          
          // Use the pre-loaded source or resume playback for minimal latency
          player.resume();
          break;
      }
    } catch (e, s) {
      AppLogger().error('Failed to play track $trackId', e, s);
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

  void play({int? totalSteps}) {
    if (_isPlaying) return;

    if (totalSteps != null) {
      _totalSteps = totalSteps;
    }

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
    if (step >= 0 && step < _totalSteps) {
      _currentStep = step;
      currentStepNotifier.value = _currentStep;
    }
  }

  void updateLoopLength(int totalSteps) {
    _totalSteps = totalSteps;
  }

  void _startSequencer() {
    // Calculate a slightly shorter duration to compensate for processing time
    // This helps ensure audio playback happens closer to the beat
    final adjustedDuration = math.max(stepDuration - 15, 1); // 15ms compensation, minimum 1ms
    
    _sequencerTimer = Timer.periodic(
      Duration(milliseconds: adjustedDuration),
      (timer) => _onSequencerTick(),
    );
  }

  void _onSequencerTick() {
    final tracks = _trackRepository.tracks;
    final nextStep = (_currentStep + 1) % _totalSteps;
    
    // First, prepare the next step's audio to reduce latency
    // This technique is called "look-ahead scheduling"
    _prepareNextStepAudio(tracks, nextStep);
    
    // Play active steps for each track with minimal latency
    for (final track in tracks) {
      if (!track.isMuted) {
        // Play step sequencer hits if within track's step range
        if (_currentStep < track.steps.length) {
          final step = track.steps[_currentStep];
          if (step.isActive) {
            // Fire and forget - don't await playback
            playTrackSample(
              track.id,
              volume: track.volume * step.velocity,
            );
          }
        }

        // Play any notes at this step for piano roll tracks
        // Notes can be anywhere within the total song length
        for (final note in track.notes) {
          if (note.step == _currentStep) {
            if (track.samplePath != null) {
              // Fire and forget - don't await playback
              playTrackSample(
                track.id,
                pitch: note.pitch,
                volume: track.volume * (note.velocity / 127.0),
              );
            } else {
              playNote(note.pitch, note.velocity);
            }
          }
        }
      }
    }

    // Update UI after triggering audio playback
    currentStepNotifier.value = _currentStep;

    _currentStep++;

    // Always loop back to start if at end
    if (_currentStep >= _totalSteps) {
      _currentStep = 0;
    }
  }
  
  // Look-ahead scheduling to prepare audio for the next step
  void _prepareNextStepAudio(List<Track> tracks, int step) {
    // This method prepares audio players for the next step
    // but doesn't actually play them yet
    for (final track in tracks) {
      if (!track.isMuted && step < track.steps.length) {
        final sourceType = _trackSourceTypes[track.id];
        if (sourceType == AudioSourceType.asset || sourceType == AudioSourceType.deviceFile) {
          final players = _audioPlayers[track.id];
          if (players != null) {
            // Find the next player that will be used
            final nextIndex = (_playerIndexes[track.id] ?? 0);
            final nextPlayer = players[nextIndex];
            
            // Ensure it's ready to play instantly when needed
            nextPlayer.setSource(_preloadedSources[track.id]!);
          }
        }
      }
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
