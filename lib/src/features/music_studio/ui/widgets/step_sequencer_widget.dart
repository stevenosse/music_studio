import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:collection/collection.dart';
import 'package:mstudio/src/core/routing/app_router.dart';
import 'package:mstudio/src/core/widgets/linked_scroll_controller.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/dimens.dart';
import '../../logic/music_studio_notifier.dart';
import '../../logic/music_studio_state.dart';

import 'sample_pack_explorer_widget.dart';
import 'step_sequencer_header.dart';
import 'control_button.dart';

class StepSequencerWidget extends StatefulWidget {
  const StepSequencerWidget({super.key});

  @override
  State<StepSequencerWidget> createState() => _StepSequencerWidgetState();
}

class _StepSequencerWidgetState extends State<StepSequencerWidget> {
  bool _showSamplePackExplorer = false;
  late LinkedScrollControllerGroup _horizontalScrollControllerGroup;
  late ScrollController _rulerScrollController;
  
  @override
  void initState() {
    super.initState();
    _horizontalScrollControllerGroup = LinkedScrollControllerGroup();
    _rulerScrollController = _horizontalScrollControllerGroup.addAndGet();
  }
  
  @override
  void dispose() {
    _horizontalScrollControllerGroup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicStudioNotifier>(
      builder: (context, notifier, child) {
        final state = notifier.value;

        return Stack(
          children: [
            Container(
              padding: EdgeInsets.all(Dimens.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with step numbers and sample pack explorer button
                  StepSequencerHeader(
                    state: state,
                    onToggleSamplePackExplorer: (show) {
                      setState(() {
                        _showSamplePackExplorer = show;
                      });
                    },
                    showSamplePackExplorer: _showSamplePackExplorer,
                    scrollController: _rulerScrollController,
                  ),

                  const SizedBox(height: 4),

                  // Track rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.tracks.length,
                      itemBuilder: (context, trackIndex) {
                        return TrackRow(
                          notifier: notifier,
                          state: state,
                          trackIndex: trackIndex,
                          scrollController: _horizontalScrollControllerGroup.addAndGet(),
                        );
                      },
                      itemExtent: 110,
                    ),
                  ),
                ],
              ),
            ),
            // Sample pack explorer panel as an overlay
            if (_showSamplePackExplorer)
              Positioned(
                right: Dimens.paddingMedium,
                top: Dimens.paddingMedium,
                bottom: Dimens.paddingMedium,
                width: 300, // Fixed width for the explorer
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: SamplePackExplorerWidget(
                    onSampleSelected: (sampleName, samplePath) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $sampleName to sequencer'),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TrackRow extends StatelessWidget {
  final MusicStudioNotifier notifier;
  final MusicStudioState state;
  final int trackIndex;
  final ScrollController scrollController;

  const TrackRow({
    super.key,
    required this.notifier,
    required this.state,
    required this.trackIndex,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final track = state.tracks[trackIndex];
    final isSelected = trackIndex == state.selectedTrackIndex;

    return GestureDetector(
      onTap: () => notifier.selectTrack(trackIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? track.color.withValues(alpha: 38) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Dimens.radiusMedium),
          border: Border.all(
            color: isSelected ? track.color.withValues(alpha: 128) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Track name and controls
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Track name and piano roll button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.piano,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            // Navigate to Piano Roll
                            context.router.push(PianoRollRoute(trackIndex: trackIndex));
                          },
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          tooltip: 'Open Piano Roll',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Mute and Solo buttons
                    Row(
                      children: [
                        ControlButton(
                          icon: IconsaxPlusBold.volume_slash,
                          isActive: track.isMuted,
                          activeColor: Colors.redAccent,
                          onTap: () => notifier.toggleTrackMute(trackIndex),
                        ),
                        const SizedBox(width: 4),
                        ControlButton(
                          icon: IconsaxPlusBold.headphone,
                          isActive: track.isSolo,
                          activeColor: Colors.orangeAccent,
                          onTap: () => notifier.toggleTrackSolo(trackIndex),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Volume slider
                    Row(
                      children: [
                        Icon(IconsaxPlusBold.volume_low,
                            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor: track.color,
                              inactiveTrackColor: track.color.withValues(alpha: 38),
                              thumbColor: track.color,
                              overlayColor: track.color.withValues(alpha: 26),
                            ),
                            child: Slider(
                              value: track.volume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                notifier.setTrackVolume(trackIndex, value);
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${(track.volume * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Steps grid
            Expanded(
              flex: 12,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(state.bars * 16, (stepIndex) {
                    return SequencerStep(
                      notifier: notifier,
                      state: state,
                      trackIndex: trackIndex,
                      stepIndex: stepIndex,
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SequencerStep extends StatelessWidget {
  final MusicStudioNotifier notifier;
  final MusicStudioState state;
  final int trackIndex;
  final int stepIndex;

  const SequencerStep({
    super.key,
    required this.notifier,
    required this.state,
    required this.trackIndex,
    required this.stepIndex,
  });

  Color _getStepColor(BuildContext context, bool isCurrentStep, int stepIndex) {
    if (isCurrentStep) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 70);
    }
    final isEvenBar = (stepIndex ~/ 4) % 2 == 0;
    return isEvenBar
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 85)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 110);
  }

  @override
  Widget build(BuildContext context) {
    final track = state.tracks[trackIndex];
    final note = track.notes.firstWhereOrNull(
      (n) => n.step == stepIndex,
    );
    final isActive = note != null;
    final isCurrentStep = stepIndex == state.currentStep && state.isPlaying;

    return GestureDetector(
      onTap: () => notifier.toggleStep(trackIndex, stepIndex),
      child: Container(
        width: 24,
        height: 40,
        decoration: BoxDecoration(
          color: _getStepColor(context, isCurrentStep, stepIndex),
          borderRadius: BorderRadius.circular(Dimens.radiusSmall),
        ),
        child: isActive
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: track.color,
                  borderRadius: BorderRadius.circular(Dimens.radiusSmall),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 153),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: track.color.withValues(alpha: 150),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
