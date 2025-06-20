// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [MusicStudioScreen]
class MusicStudioRoute extends PageRouteInfo<void> {
  const MusicStudioRoute({List<PageRouteInfo>? children})
      : super(MusicStudioRoute.name, initialChildren: children);

  static const String name = 'MusicStudioRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MusicStudioScreen();
    },
  );
}

/// generated route for
/// [PianoRollScreen]
class PianoRollRoute extends PageRouteInfo<PianoRollRouteArgs> {
  PianoRollRoute({
    Key? key,
    required int trackIndex,
    List<PageRouteInfo>? children,
  }) : super(
          PianoRollRoute.name,
          args: PianoRollRouteArgs(key: key, trackIndex: trackIndex),
          rawPathParams: {'trackIndex': trackIndex},
          initialChildren: children,
        );

  static const String name = 'PianoRollRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PianoRollRouteArgs>(
        orElse: () =>
            PianoRollRouteArgs(trackIndex: pathParams.getInt('trackIndex')),
      );
      return WrappedRoute(
        child: PianoRollScreen(key: args.key, trackIndex: args.trackIndex),
      );
    },
  );
}

class PianoRollRouteArgs {
  const PianoRollRouteArgs({this.key, required this.trackIndex});

  final Key? key;

  final int trackIndex;

  @override
  String toString() {
    return 'PianoRollRouteArgs{key: $key, trackIndex: $trackIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PianoRollRouteArgs) return false;
    return key == other.key && trackIndex == other.trackIndex;
  }

  @override
  int get hashCode => key.hashCode ^ trackIndex.hashCode;
}
