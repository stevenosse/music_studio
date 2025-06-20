import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'sequencer_step.dart';
import 'note.dart';

enum AudioSourceType {
  asset,
  deviceFile,
  soundfont,
}

class Track extends Equatable {
  final String id;
  final String name;
  final Color color;
  final List<SequencerStep> steps;
  final List<Note> notes;
  final bool isMuted;
  final bool isSolo;
  final double volume;
  final String? samplePath;
  final AudioSourceType audioSourceType;
  final int? baseMidiNoteForSample;
  
  const Track({
    required this.id,
    required this.name,
    required this.color,
    required this.steps,
    this.notes = const [],
    this.isMuted = false,
    this.isSolo = false,
    this.volume = 1.0,
    this.samplePath,
    this.audioSourceType = AudioSourceType.asset,
    this.baseMidiNoteForSample,
  });
  
  Track copyWith({
    String? id,
    String? name,
    Color? color,
    List<SequencerStep>? steps,
    List<Note>? notes,
    bool? isMuted,
    bool? isSolo,
    double? volume,
    String? samplePath,
    AudioSourceType? audioSourceType,
    int? baseMidiNoteForSample,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      steps: steps ?? this.steps,
      notes: notes ?? this.notes,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      volume: volume ?? this.volume,
      samplePath: samplePath ?? this.samplePath,
      audioSourceType: audioSourceType ?? this.audioSourceType,
      baseMidiNoteForSample: baseMidiNoteForSample ?? this.baseMidiNoteForSample,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'steps': steps.map((step) => step.toJson()).toList(),
      'isMuted': isMuted,
      'isSolo': isSolo,
      'volume': volume,
      'samplePath': samplePath,
      'audioSourceType': audioSourceType.name,
      'baseMidiNoteForSample': baseMidiNoteForSample,
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      steps: (json['steps'] as List)
          .map((stepJson) => SequencerStep.fromJson(stepJson as Map<String, dynamic>))
          .toList(),
      isMuted: json['isMuted'] as bool? ?? false,
      isSolo: json['isSolo'] as bool? ?? false,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      samplePath: json['samplePath'] as String?,
      audioSourceType: AudioSourceType.values.firstWhere(
        (e) => e.name == json['audioSourceType'],
        orElse: () => AudioSourceType.asset,
      ),
      baseMidiNoteForSample: json['baseMidiNoteForSample'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    color,
    steps,
    notes,
    isMuted,
    isSolo,
    volume,
    samplePath,
    audioSourceType,
    baseMidiNoteForSample,
  ];
}