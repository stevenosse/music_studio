import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color success;
  final Color onSuccess;
  final Color gridLine;
  final Color gridLineMajor;
  final Color pianoWhiteKey;
  final Color pianoBlackKey;
  final Color noteDefault;
  final Color noteSelected;
  final Color playhead;
  final Color timelineBackground;
  final Color velocityEditor;

  const CustomColors({
    required this.success,
    required this.onSuccess,
    required this.gridLine,
    required this.gridLineMajor,
    required this.pianoWhiteKey,
    required this.pianoBlackKey,
    required this.noteDefault,
    required this.noteSelected,
    required this.playhead,
    required this.timelineBackground,
    required this.velocityEditor,
  });

  @override
  CustomColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? gridLine,
    Color? gridLineMajor,
    Color? pianoWhiteKey,
    Color? pianoBlackKey,
    Color? noteDefault,
    Color? noteSelected,
    Color? playhead,
    Color? timelineBackground,
    Color? velocityEditor,
  }) {
    return CustomColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      gridLine: gridLine ?? this.gridLine,
      gridLineMajor: gridLineMajor ?? this.gridLineMajor,
      pianoWhiteKey: pianoWhiteKey ?? this.pianoWhiteKey,
      pianoBlackKey: pianoBlackKey ?? this.pianoBlackKey,
      noteDefault: noteDefault ?? this.noteDefault,
      noteSelected: noteSelected ?? this.noteSelected,
      playhead: playhead ?? this.playhead,
      timelineBackground: timelineBackground ?? this.timelineBackground,
      velocityEditor: velocityEditor ?? this.velocityEditor,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      gridLineMajor: Color.lerp(gridLineMajor, other.gridLineMajor, t)!,
      pianoWhiteKey: Color.lerp(pianoWhiteKey, other.pianoWhiteKey, t)!,
      pianoBlackKey: Color.lerp(pianoBlackKey, other.pianoBlackKey, t)!,
      noteDefault: Color.lerp(noteDefault, other.noteDefault, t)!,
      noteSelected: Color.lerp(noteSelected, other.noteSelected, t)!,
      playhead: Color.lerp(playhead, other.playhead, t)!,
      timelineBackground: Color.lerp(timelineBackground, other.timelineBackground, t)!,
      velocityEditor: Color.lerp(velocityEditor, other.velocityEditor, t)!,
    );
  }

  // Light theme colors inspired by professional DAWs
  static const light = CustomColors(
    success: Color(0xFF4CAF50),
    onSuccess: Color(0xFFFFFFFF),
    gridLine: Color(0xFFE0E0E0),
    gridLineMajor: Color(0xFFBDBDBD),
    pianoWhiteKey: Color(0xFFFAFAFA),
    pianoBlackKey: Color(0xFF424242),
    noteDefault: Color(0xFF2C7BE5),
    noteSelected: Color(0xFFFF9800),
    playhead: Color(0xFFE53935),
    timelineBackground: Color(0xFFEEEEEE),
    velocityEditor: Color(0xFF00B8D4),
  );

  // Dark theme colors inspired by professional DAWs like Ableton, FL Studio
  static const dark = CustomColors(
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF1B5E20),
    gridLine: Color(0xFF2C2C3C),
    gridLineMajor: Color(0xFF3C3C4C),
    pianoWhiteKey: Color(0xFF2D2D3F),
    pianoBlackKey: Color(0xFF1A1A27),
    noteDefault: Color(0xFF3699FF),
    noteSelected: Color(0xFFFF5252),
    playhead: Color(0xFFFF5252),
    timelineBackground: Color(0xFF252536),
    velocityEditor: Color(0xFF00E5FF),
  );
}