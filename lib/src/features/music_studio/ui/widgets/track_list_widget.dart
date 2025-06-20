import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/dimens.dart';
import '../../logic/music_studio_notifier.dart';

class TrackListWidget extends StatelessWidget {
  const TrackListWidget({super.key});

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
                    onPressed: () => notifier.addTrack(),
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
                                
                                // Track actions
                                PopupMenuButton<String>(
                                  onSelected: (value) => _handleTrackAction(context, notifier, index, value),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'rename',
                                      child: Text('Rename'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                  child: Icon(
                                    IconsaxPlusLinear.more,
                                    size: 16,
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: Dimens.spacingSmall),
                            
                            // Track controls
                            Row(
                              children: [
                                // Mute button
                                _buildControlButton(
                                  context: context,
                                  icon: track.isMuted ? IconsaxPlusLinear.volume_slash : IconsaxPlusLinear.volume_high,
                                  isActive: track.isMuted,
                                  onPressed: () => notifier.toggleTrackMute(index),
                                  tooltip: track.isMuted ? 'Unmute' : 'Mute',
                                ),
                                
                                SizedBox(width: Dimens.spacingXSmall),
                                
                                // Solo button
                                _buildControlButton(
                                  context: context,
                                  icon: IconsaxPlusLinear.headphone,
                                  isActive: track.isSolo,
                                  onPressed: () => notifier.toggleTrackSolo(index),
                                  tooltip: track.isSolo ? 'Unsolo' : 'Solo',
                                ),
                                
                                const Spacer(),
                                
                                // Volume indicator
                                Text(
                                  '${(track.volume * 100).toInt()}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
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
  
  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Dimens.radiusXSmall),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimens.radiusXSmall),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
  
  void _handleTrackAction(BuildContext context, MusicStudioNotifier notifier, int index, String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, notifier, index);
        break;
      case 'delete':
        notifier.removeTrack(index);
        break;
    }
  }
  
  void _showRenameDialog(BuildContext context, MusicStudioNotifier notifier, int index) {
    final controller = TextEditingController(text: notifier.value.tracks[index].name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Track'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Track Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notifier.updateTrackName(index, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}