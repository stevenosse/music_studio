import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Note extends Equatable {
  final String id;
  final int pitch; // MIDI note number (0-127)
  final int step; // In steps
  final int duration; // In steps
  final int velocity; // 0-127
  final int trackIndex;
  final Color color;

  const Note({
    required this.id,
    required this.pitch,
    required this.step,
    this.duration = 1,
    this.velocity = 100,
    required this.trackIndex,
    required this.color,
  });

  String get note {
    // MIDI note numbers: C0 is 12, C1 is 24, C2 is 36, etc.
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (pitch / 12).floor();
    final noteIndex = pitch % 12;
    return '${notes[noteIndex]}$octave';
  }

  Note copyWith({
    String? id,
    int? pitch,
    int? step,
    int? duration,
    int? velocity,
    int? trackIndex,
    Color? color,
  }) {
    return Note(
      id: id ?? this.id,
      pitch: pitch ?? this.pitch,
      step: step ?? this.step,
      duration: duration ?? this.duration,
      velocity: velocity ?? this.velocity,
      trackIndex: trackIndex ?? this.trackIndex,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pitch,
        step,
        duration,
        velocity,
        trackIndex,
        color,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pitch': pitch,
      'step': step,
      'duration': duration,
      'velocity': velocity,
      'trackIndex': trackIndex,
      'color': color.toARGB32(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      pitch: json['pitch'] as int,
      step: json['step'] as int,
      duration: json['duration'] as int? ?? 1,
      velocity: json['velocity'] as int? ?? 100,
      trackIndex: json['trackIndex'] as int,
      color: Color(json['color'] as int),
    );
  }


}