import 'package:equatable/equatable.dart';

class SequencerStep extends Equatable {
  final bool isActive;
  final double velocity;
  final int? noteNumber;
  final Duration? duration;
  
  const SequencerStep({
    required this.isActive,
    this.velocity = 1.0,
    this.noteNumber,
    this.duration,
  });
  
  SequencerStep copyWith({
    bool? isActive,
    double? velocity,
    int? noteNumber,
    Duration? duration,
  }) {
    return SequencerStep(
      isActive: isActive ?? this.isActive,
      velocity: velocity ?? this.velocity,
      noteNumber: noteNumber ?? this.noteNumber,
      duration: duration ?? this.duration,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'velocity': velocity,
      'noteNumber': noteNumber,
      'duration': duration?.inMilliseconds,
    };
  }

  factory SequencerStep.fromJson(Map<String, dynamic> json) {
    return SequencerStep(
      isActive: json['isActive'] as bool? ?? false,
      velocity: (json['velocity'] as num?)?.toDouble() ?? 1.0,
      noteNumber: json['noteNumber'] as int?,
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'] as int)
          : null,
    );
  }

  @override
  List<Object?> get props => [isActive, velocity, noteNumber, duration];
}