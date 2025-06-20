import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/dimens.dart';
import '../../logic/music_studio_notifier.dart';

class TransportControlsWidget extends StatelessWidget {
  const TransportControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicStudioNotifier>(
      builder: (context, notifier, child) {
        final state = notifier.value;
        
        return Container(
          padding: EdgeInsets.all(Dimens.paddingMedium),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Dimens.radiusMedium),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Play/Pause Button
              IconButton(
                onPressed: () async {
                  if (state.isPlaying) {
                    await notifier.pause();
                  } else {
                    notifier.play();
                  }
                },
                icon: Icon(
                  state.isPlaying ? IconsaxPlusLinear.pause : IconsaxPlusLinear.play,
                  size: Dimens.iconSizeLarge,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: state.isPlaying 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  foregroundColor: state.isPlaying 
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              
              SizedBox(width: Dimens.spacingSmall),
              
              // Stop Button
              IconButton(
                onPressed: () async => await notifier.stop(),
                icon: Icon(
                  IconsaxPlusLinear.stop,
                  size: Dimens.iconSizeM,
                ),
              ),
              
              SizedBox(width: Dimens.spacingSmall),
              
              // Record Button
              IconButton(
                onPressed: () => notifier.record(),
                icon: Icon(
                  IconsaxPlusLinear.record,
                  size: Dimens.iconSizeM,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: state.isRecording 
                      ? Colors.red
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  foregroundColor: state.isRecording 
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              
              SizedBox(width: Dimens.spacingLarge),
              
              // BPM Control
              Row(
                children: [
                  Text(
                    'BPM:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  SizedBox(width: Dimens.spacingSmall),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      key: ValueKey(state.bpm),
                      initialValue: state.bpm.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: Dimens.paddingSmall,
                          vertical: Dimens.paddingXSmall,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimens.radiusSmall),
                        ),
                      ),
                      onChanged: (value) {
                        final newBpm = int.tryParse(value);
                        if (newBpm != null && newBpm >= 60 && newBpm <= 200) {
                          notifier.setBpm(newBpm);
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(width: Dimens.spacingLarge),
              
              // Position Indicator
              Row(
                children: [
                  Text(
                    'Position:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  SizedBox(width: Dimens.spacingSmall),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimens.paddingMedium,
                      vertical: Dimens.paddingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(Dimens.radiusSmall),
                    ),
                    child: Text(
                      '${state.currentStep + 1}/${state.stepsPerBar}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}