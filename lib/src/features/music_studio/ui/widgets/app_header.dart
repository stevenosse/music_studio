import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:mstudio/src/core/theme/dimens.dart';
import 'package:mstudio/src/features/music_studio/logic/music_studio_notifier.dart';
import 'package:mstudio/src/features/music_studio/logic/music_studio_state.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'control_button.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MusicStudioNotifier>();
    final state = notifier.value;
    final theme = Theme.of(context);

    final buttonColors = WindowButtonColors(
      iconNormal: theme.colorScheme.onSurfaceVariant,
      mouseOver: theme.colorScheme.surfaceContainerHighest,
      mouseDown: theme.colorScheme.primaryContainer,
      iconMouseOver: theme.colorScheme.primary,
      iconMouseDown: theme.colorScheme.onPrimaryContainer,
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: theme.colorScheme.onSurfaceVariant,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Dimens.paddingSmall,
        horizontal: Dimens.paddingLarge,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          // Project title section
          Expanded(
            flex: 2,
            child: Text(
              state.projectName.isNotEmpty ? state.projectName : 'Untitled Project',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Center section with main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BpmControlWidget(notifier: notifier, state: state),
              const SizedBox(width: Dimens.spacingLarge),
              TransportControlsWidget(notifier: notifier, state: state),
              const SizedBox(width: Dimens.spacingMedium),
              ControlButton(
                icon: state.isLooping ? IconsaxPlusBold.repeate_one : IconsaxPlusLinear.repeate_one,
                label: 'Loop',
                isActive: state.isLooping,
                activeColor: Theme.of(context).colorScheme.primary,
                onTap: notifier.toggleLooping,
              ),
              const SizedBox(width: Dimens.spacingMedium),
              ControlButton(
                icon: state.isMetronomeEnabled ? IconsaxPlusBold.volume_high : IconsaxPlusLinear.volume_slash,
                label: 'Metronome',
                isActive: state.isMetronomeEnabled,
                activeColor: Theme.of(context).colorScheme.primary,
                onTap: notifier.toggleMetronome,
              ),
            ],
          ),

          // Right section with project actions and window controls
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ProjectActionsWidget(notifier: notifier),
                const SizedBox(width: Dimens.spacingMedium),
                MinimizeWindowButton(colors: buttonColors),
                MaximizeWindowButton(colors: buttonColors),
                CloseWindowButton(colors: closeButtonColors),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

class BpmControlWidget extends StatelessWidget {
  final MusicStudioNotifier notifier;
  final MusicStudioState state;

  const BpmControlWidget({
    super.key,
    required this.notifier,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Dimens.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingSmall),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BPM',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Dimens.spacingSmall),
          IconButton(
            icon: const Icon(Icons.remove),
            iconSize: 16,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => notifier.setBpm(state.bpm > 20 ? state.bpm - 1 : 20),
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Container(
            width: 48,
            height: 32,
            alignment: Alignment.center,
            child: TextFormField(
              key: ValueKey('bpm_${state.bpm}'),
              initialValue: state.bpm.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
              ),
              onFieldSubmitted: (value) {
                final newBpm = int.tryParse(value);
                if (newBpm != null && newBpm >= 20 && newBpm <= 999) {
                  notifier.setBpm(newBpm);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 16,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => notifier.setBpm(state.bpm < 999 ? state.bpm + 1 : 999),
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class TransportControlsWidget extends StatelessWidget {
  final MusicStudioNotifier notifier;
  final MusicStudioState state;

  const TransportControlsWidget({
    super.key,
    required this.notifier,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingSmall),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Dimens.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button in the center for better prominence
          IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              color: theme.colorScheme.primary,
            ),
            tooltip: state.isPlaying ? 'Pause' : 'Play',
            iconSize: Dimens.iconSizeLarge,
            padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingSmall),
            onPressed: () async {
              if (state.isPlaying) {
                await notifier.pause();
              } else {
                notifier.play();
              }
            },
          ),
          const SizedBox(width: Dimens.spacingXSmall),
          // Record button
          IconButton(
            icon: Icon(
              Icons.record_voice_over,
              color: state.isRecording ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Record',
            iconSize: Dimens.iconSizeM,
            visualDensity: VisualDensity.compact,
            onPressed: () => notifier.record(),
          ),
          // Stop button
          IconButton(
            icon: Icon(
              Icons.stop,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Stop',
            iconSize: Dimens.iconSizeM,
            visualDensity: VisualDensity.compact,
            onPressed: notifier.stop,
          ),
        ],
      ),
    );
  }
}

class ProjectActionsWidget extends StatelessWidget {
  final MusicStudioNotifier notifier;

  const ProjectActionsWidget({
    super.key,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Dimens.radiusMedium),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(IconsaxPlusLinear.menu, color: theme.colorScheme.onSurfaceVariant),
        tooltip: 'Project Actions',
        onSelected: (value) {
          if (value == 'new') notifier.newProject();
          if (value == 'load') notifier.loadProject();
          if (value == 'load_demo_project') notifier.loadDemoSong();
          if (value == 'save') notifier.saveProject();
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'new',
            child: ListTile(leading: Icon(IconsaxPlusLinear.add_square), title: Text('New Project')),
          ),
          const PopupMenuItem<String>(
            value: 'load',
            child: ListTile(leading: Icon(IconsaxPlusLinear.folder_open), title: Text('Load Project')),
          ),
          const PopupMenuItem<String>(
            value: 'load_demo_project',
            child: ListTile(leading: Icon(IconsaxPlusLinear.music), title: Text('Load Demo Project')),
          ),
          const PopupMenuItem<String>(
            value: 'save',
            child: ListTile(leading: Icon(IconsaxPlusLinear.document_download), title: Text('Save Project')),
          ),
        ],
      ),
    );
  }
}
