import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:mstudio/src/features/music_studio/ui/widgets/instrument_selection_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/dimens.dart';
import '../../logic/music_studio_notifier.dart';

class TrackListWidget extends StatelessWidget {
  const TrackListWidget({super.key});

  Future<void> _showInstrumentDialog(
      BuildContext context, MusicStudioNotifier notifier, {int? trackIndex}) async {
    final selectedInstrument = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => InstrumentSelectionDialog(
        samplePacks: notifier.value.samplePacks,
        soundfonts: notifier.value.soundfonts,
      ),
    );

    if (selectedInstrument != null) {
      if (trackIndex != null) {
        notifier.updateTrackInstrument(trackIndex, selectedInstrument);
      } else {
        notifier.addTrackFromInstrument(selectedInstrument);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicStudioNotifier>(
      builder: (context, notifier, child) {
        final state = notifier.value;
        
        return Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(Dimens.paddingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Tracks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showInstrumentDialog(context, notifier),
                    icon: const Icon(IconsaxPlusLinear.add),
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: 'Add Track',
                  ),
                ],
              ),
            ),
            
            // Track List
            Expanded(
              child: ListView.builder(
                itemCount: state.tracks.length,
                itemBuilder: (context, index) {
                  final track = state.tracks[index];
                  final isSelected = index == state.selectedTrackIndex;
                  
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: Dimens.paddingSmall,
                      vertical: Dimens.paddingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(Dimens.radiusSmall),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => notifier.selectTrack(index),
                      borderRadius: BorderRadius.circular(Dimens.radiusSmall),
                      child: Padding(
                        padding: EdgeInsets.all(Dimens.paddingSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Track header
                            Row(
                              children: [
                                // Color indicator
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: track.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: Dimens.spacingSmall),
                                
                                // Track name
                                Expanded(
                                  child: Text(
                                    track.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                

                              ],
                            ),
                            
                            SizedBox(height: Dimens.spacingSmall),
                            
                            // Track controls
                            Row(
                              children: [
                                // Mute button
                                IconButton(
                                  onPressed: () => notifier.toggleTrackMute(index),
                                  icon: Icon(
                                    track.isMuted
                                        ? IconsaxPlusBold.volume_slash
                                        : IconsaxPlusLinear.volume_high,
                                    color: track.isMuted
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                  iconSize: 18,
                                  tooltip: 'Mute',
                                ),

                                // Solo button
                                IconButton(
                                  onPressed: () => notifier.toggleTrackSolo(index),
                                  icon: Icon(
                                    track.isSolo
                                        ? IconsaxPlusBold.headphone
                                        : IconsaxPlusLinear.headphone,
                                    color: track.isSolo
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                  iconSize: 18,
                                  tooltip: 'Solo',
                                ),

                                // More options
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'change_instrument') {
                                      _showInstrumentDialog(context, notifier, trackIndex: index);
                                    } else if (value == 'delete') {
                                      notifier.removeTrack(index);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'change_instrument',
                                      child: Text('Change Instrument'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                  icon: const Icon(IconsaxPlusLinear.more),
                                  tooltip: 'More options',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
}
}