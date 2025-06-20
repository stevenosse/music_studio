import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

/// Repository responsible for managing track data.
/// Acts as a single source of truth for track data in the application.
class TrackRepository {
  static final TrackRepository _instance = TrackRepository._internal();
  factory TrackRepository() => _instance;
  TrackRepository._internal();

  final List<Track> _tracks = [];
  final ValueNotifier<List<Track>> tracksNotifier =
      ValueNotifier<List<Track>>([]);

  // Stream controller for track updates
  final _trackStreamController = StreamController<List<Track>>.broadcast();
  Stream<List<Track>> get trackStream => _trackStreamController.stream;

  /// Get the current tracks
  List<Track> get tracks => List.unmodifiable(_tracks);

  /// Update tracks with a new list
  void updateTracks(List<Track> newTracks) {
    _tracks.clear();
    _tracks.addAll(newTracks);

    // Create a new list to ensure ValueNotifier detects the change
    final updatedList = List<Track>.from(_tracks);

    // Notify listeners
    tracksNotifier.value = updatedList;
    _trackStreamController.add(List.unmodifiable(_tracks));
  }

  /// Update a single track
  void updateTrack(Track updatedTrack) {
    final index = _tracks.indexWhere((track) => track.id == updatedTrack.id);
    if (index != -1) {
      _tracks[index] = updatedTrack;

      // Create a new list to ensure ValueNotifier detects the change
      final updatedList = List<Track>.from(_tracks);

      // Notify listeners
      tracksNotifier.value = updatedList;
      _trackStreamController.add(List.unmodifiable(_tracks));
    }
  }

  /// Add a new track
  void addTrack(Track track) {
    _tracks.add(track);

    // Create a new list to ensure ValueNotifier detects the change
    final updatedList = List<Track>.from(_tracks);

    // Notify listeners
    tracksNotifier.value = updatedList;
    _trackStreamController.add(List.unmodifiable(_tracks));
  }

  /// Remove a track by id
  void removeTrackById(String id) {
    _tracks.removeWhere((track) => track.id == id);

    // Create a new list to ensure ValueNotifier detects the change
    final updatedList = List<Track>.from(_tracks);

    // Notify listeners
    tracksNotifier.value = updatedList;
    _trackStreamController.add(List.unmodifiable(_tracks));
  }

  /// Remove a track by index
  void removeTrackByIndex(int index) {
    if (index >= 0 && index < _tracks.length) {
      _tracks.removeAt(index);

      // Notify listeners
      tracksNotifier.value = List.unmodifiable(_tracks);
      _trackStreamController.add(List.unmodifiable(_tracks));
    }
  }

  /// Save tracks to persistent storage
  Future<void> saveTracks(String projectName, int bpm, int stepsPerBar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectData = {
        'name': projectName,
        'bpm': bpm,
        'stepsPerBar': stepsPerBar,
        'tracks': _tracks.map((track) => track.toJson()).toList(),
      };

      await prefs.setString('current_project', jsonEncode(projectData));
      return;
    } catch (e) {
      debugPrint('Failed to save project: $e');
      throw Exception('Failed to save project: $e');
    }
  }

  /// Load tracks from persistent storage
  Future<Map<String, dynamic>> loadTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectJson = prefs.getString('current_project');

      if (projectJson != null) {
        final projectData = jsonDecode(projectJson) as Map<String, dynamic>;
        final loadedTracks = (projectData['tracks'] as List)
            .map((trackJson) =>
                Track.fromJson(trackJson as Map<String, dynamic>))
            .toList();

        _tracks.clear();
        _tracks.addAll(loadedTracks);

        // Notify listeners
        tracksNotifier.value = List.unmodifiable(_tracks);
        _trackStreamController.add(List.unmodifiable(_tracks));

        return {
          'projectName': projectData['name'] as String? ?? 'Untitled Project',
          'bpm': projectData['bpm'] as int? ?? 120,
          'stepsPerBar': projectData['stepsPerBar'] as int? ?? 32,
          'tracks': loadedTracks,
        };
      }

      return {
        'projectName': 'Untitled Project',
        'bpm': 120,
        'stepsPerBar': 32,
        'tracks': <Track>[],
      };
    } catch (e) {
      debugPrint('Failed to load project: $e');
      throw Exception('Failed to load project: $e');
    }
  }

  void dispose() {
    tracksNotifier.dispose();
    _trackStreamController.close();
  }
}
