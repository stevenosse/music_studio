import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:collection/collection.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicStudioNotifier>(
      builder: (context, notifier, child) {
        final state = notifier.value;

        return Container(
          padding: EdgeInsets.all(Dimens.paddingMedium),
          child: Row(
            children: [
              // Main sequencer area
              Expanded(
                flex: _showSamplePackExplorer ? 2 : 1,
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
                    ),

                    const SizedBox(height: 4),

                    // Track rows
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.tracks.length,
                        itemBuilder: (context, trackIndex) {
                          return _buildTrackRow(context, notifier, state, trackIndex);
                        },
                        itemExtent: 110,
                      ),
                    ),
                  ],
                ),
              ),

              // Sample pack explorer panel
              if (_showSamplePackExplorer) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
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
                        // Sample is already added by SamplePackExplorerWidget
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
            ],
          ),
        );
      },
    );
  }

  Color _getStepColor(BuildContext context, bool isCurrentStep, int stepIndex) {
    if (isCurrentStep) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 51);
    }
    final isEvenBar = (stepIndex ~/ 4) % 2 == 0;
    return isEvenBar
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 77)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 102);
  }

  Widget _buildStep(
      BuildContext context, MusicStudioNotifier notifier, MusicStudioState state, int trackIndex, int stepIndex) {
    final track = state.tracks[trackIndex];
    final note = track.notes.firstWhereOrNull(
      (n) => n.step == stepIndex,
    );
    final isActive = note != null;
    final isCurrentStep = stepIndex == state.currentStep && state.isPlaying;

    return GestureDetector(
      onTap: () {
        notifier.toggleStep(trackIndex, stepIndex);
      },
      child: Container(
        width: 24,
        height: 100, // Increased height
        decoration: BoxDecoration(
          color: _getStepColor(context, isCurrentStep, stepIndex),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 26),
              width: 0.5,
            ),
            right: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 26),
              width: 0.5,
            ),
          ),
        ),
        child: isActive
            ? Container(
                margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  color: track.color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: track.color.withValues(alpha: 128),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTrackRow(BuildContext context, MusicStudioNotifier notifier, MusicStudioState state, int trackIndex) {
    final track = state.tracks[trackIndex];
    final isSelected = trackIndex == state.selectedTrackIndex;

    return GestureDetector(
      onTap: () => notifier.selectTrack(trackIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? track.color.withValues(alpha: 38) : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimens.radiusMedium),
          border: Border.all(
            color: isSelected ? track.color.withValues(alpha: 128) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Track name and controls
            SizedBox(
              width: 142, // Slightly less than the ruler spacer
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Track name and piano roll button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Mute and Solo buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ControlButton(
                        icon: IconsaxPlusBold.volume_slash,
                        label: 'Mute',
                        isActive: track.isMuted,
                        activeColor: Colors.redAccent,
                        onTap: () => notifier.toggleTrackMute(trackIndex),
                      ),

                      ControlButton(
                        icon: IconsaxPlusBold.headphone,
                        label: 'Solo',
                        isActive: track.isSolo,
                        activeColor: Colors.orangeAccent,
                        onTap: () => notifier.toggleTrackSolo(trackIndex),
                      ),

                    ],
                  ),

                  const SizedBox(height: 4),

                  // Volume slider
                  SizedBox(
                    height: 20,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: track.color,
                        inactiveTrackColor: track.color.withValues(alpha: 77),
                        thumbColor: track.color,
                      ),
                      child: Slider(
                        value: track.volume,
                        onChanged: (value) {
                          notifier.setTrackVolume(trackIndex, value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Steps grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(32, (stepIndex) {
                    return _buildStep(context, notifier, state, trackIndex, stepIndex);
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
