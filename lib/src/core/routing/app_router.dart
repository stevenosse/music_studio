import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:mstudio/src/features/music_studio/ui/music_studio_screen.dart';
import 'package:mstudio/src/features/music_studio/ui/piano_roll_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> routes = [
    AutoRoute(page: MusicStudioRoute.page, initial: true),
    AutoRoute(page: PianoRollRoute.page),
  ];
}
