import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mstudio/src/shared/locator.dart';
import 'package:provider/provider.dart';

import '../logic/music_studio_notifier.dart';
// import 'widgets/transport_controls_widget.dart'; // No longer directly used here
import 'widgets/app_header.dart';
import 'widgets/track_list_widget.dart';
import 'widgets/step_sequencer_widget.dart';

@RoutePage()
class MusicStudioScreen extends StatelessWidget implements AutoRouteWrapper {
  const MusicStudioScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: locator<MusicStudioNotifier>(),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicStudioNotifier>(
      builder: (context, notifier, child) {
        return Scaffold(
          body: Column(
            children: [
              Flexible(child: const AppHeader()),

              // Main content area
              Expanded(
                flex: 9,
                child: Row(
                  children: [
                    // Track list on the left
                    SizedBox(
                      width: 200,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const TrackListWidget(),
                      ),
                    ),

                    // Step sequencer on the right
                    const Expanded(
                      child: StepSequencerWidget(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
