import 'package:equatable/equatable.dart';

class NoteDragData extends Equatable {
  final int initialStep;
  final int initialPitch;

  const NoteDragData({
    required this.initialStep,
    required this.initialPitch,
  });

  @override
  List<Object?> get props => [initialStep, initialPitch];
}
