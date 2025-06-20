import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:mstudio/src/shared/locator.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/dimens.dart';
import '../logic/music_studio_notifier.dart';
import 'widgets/transport_controls_widget.dart';
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
          appBar: AppBar(
            title: Text(notifier.value.projectName),
            actions: [
              IconButton(
                icon: const Icon(IconsaxPlusLinear.document_download),
                onPressed: () => notifier.saveProject(),
              ),
              IconButton(
                icon: const Icon(IconsaxPlusLinear.folder_open),
                onPressed: () => notifier.loadProject(),
              ),
              IconButton(
                icon: const Icon(IconsaxPlusLinear.add),
                onPressed: () => notifier.newProject(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Transport controls at the top
              Container(
                padding: const EdgeInsets.all(Dimens.spacing),
                child: const TransportControlsWidget(),
              ),

              // Main content area
              Expanded(
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
