import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/dimens.dart';
import '../../logic/music_studio_state.dart';

class StepSequencerHeader extends StatelessWidget {
  final MusicStudioState state;
  final ValueChanged<bool> onToggleSamplePackExplorer;
  final bool showSamplePackExplorer;

  const StepSequencerHeader({
    super.key,
    required this.state,
    required this.onToggleSamplePackExplorer,
    required this.showSamplePackExplorer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step Sequencer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                onToggleSamplePackExplorer(!showSamplePackExplorer);
              },
              icon: Icon(
                showSamplePackExplorer
                    ? IconsaxPlusBold.close_circle
                    : IconsaxPlusBold.music_library_2,
                size: 18,
              ),
              label: Text(showSamplePackExplorer ? 'Close' : 'Sample Packs'),
              style: OutlinedButton.styleFrom(
                foregroundColor: showSamplePackExplorer
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: showSamplePackExplorer
                      ? Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.5)
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Dimens.spacingMedium),
        // _buildStepRuler will be refactored into a separate widget
        // For now, we'll keep it as a method call within the main widget
        // and pass the state.
        _StepRuler(state: state),
      ],
    );
  }
}

class _StepRuler extends StatelessWidget {
  final MusicStudioState state;

  const _StepRuler({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Track name column spacer
          const SizedBox(width: 150), // Increased width for track controls

          // Step numbers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(32, (index) {
                  final isCurrentStep = index == state.currentStep && state.isPlaying;
                  final isBarStart = index % 4 == 0;
                  final isBeatStart = index % 4 != 0 && index % 2 == 0;

                  return Container(
                    width: 24,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isBarStart
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                              : isBeatStart
                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isCurrentStep)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        if (isBarStart)
                          Center(
                            child: Text(
                              (index ~/ 4 + 1).toString(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
