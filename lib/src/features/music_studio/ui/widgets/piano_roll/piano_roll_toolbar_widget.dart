import 'package:flutter/material.dart';
import 'package:mstudio/src/features/music_studio/logic/music_studio_notifier.dart';
import 'package:provider/provider.dart';

import 'package:mstudio/src/core/theme/dimens.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_notifier.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_state.dart';

class PianoRollToolbarWidget extends StatelessWidget {
  final VoidCallback onQuantize;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomFit;

  const PianoRollToolbarWidget({
    super.key,
    required this.onQuantize,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomFit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Consumer<PianoRollNotifier>(
        builder: (context, pianoRollNotifier, child) {
          final musicStudioNotifier = context.watch<MusicStudioNotifier>();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildModeToggle(context, pianoRollNotifier),
                const SizedBox(width: 16),
                _buildSnapSettings(context, pianoRollNotifier),
                const SizedBox(width: 16),
                _buildQuantizeButton(context),
                const SizedBox(width: 16),
                _buildBarCounter(context, musicStudioNotifier),
                const Spacer(),
                _buildZoomControls(context, pianoRollNotifier),
                const SizedBox(width: 8),
                _buildZoomSlider(context, pianoRollNotifier),
                const SizedBox(width: 16),
                _buildZoomIndicator(context, pianoRollNotifier),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context, PianoRollNotifier notifier) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            icon: Icons.mouse,
            label: 'Select',
            isSelected: notifier.value.tool == PianoRollTool.select,
            onPressed: () => notifier.setTool(PianoRollTool.select),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.edit,
            label: 'Draw',
            isSelected: notifier.value.tool == PianoRollTool.draw,
            onPressed: () => notifier.setTool(PianoRollTool.draw),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.volume_off,
            label: 'Mute',
            isSelected: notifier.value.tool == PianoRollTool.mute,
            onPressed: () => notifier.setTool(PianoRollTool.mute),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapSettings(BuildContext context, PianoRollNotifier notifier) {
    final theme = Theme.of(context);
    final isSnapEnabled = notifier.value.isSnapEnabled;

    return PopupMenuButton<SnapResolution>(
      onSelected: (resolution) => notifier.setSnapResolution(resolution),
      itemBuilder: (context) => SnapResolution.values
          .map((resolution) => PopupMenuItem(
                value: resolution,
                child: Text(resolution.label),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.grid_on,
              size: 16,
              color: isSnapEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              isSnapEnabled ? notifier.value.snapResolution.label : 'Off',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSnapEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantizeButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onQuantize,
      icon: const Icon(Icons.straighten, size: 16),
      label: Text(
        'Quantize',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context, PianoRollNotifier notifier) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onZoomOut,
          icon: const Icon(Icons.zoom_out),
          tooltip: 'Zoom Out',
        ),
        IconButton(
          onPressed: onZoomFit,
          icon: const Icon(Icons.fit_screen),
          tooltip: 'Zoom to Fit',
        ),
        IconButton(
          onPressed: onZoomIn,
          icon: const Icon(Icons.zoom_in),
          tooltip: 'Zoom In',
        ),
      ],
    );
  }

  Widget _buildZoomIndicator(BuildContext context, PianoRollNotifier notifier) {
    final theme = Theme.of(context);
    final zoomPercentage = (notifier.value.zoomLevel * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$zoomPercentage%',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildZoomSlider(BuildContext context, PianoRollNotifier notifier) {
    return SizedBox(
      width: 120,
      child: Slider(
        value: notifier.value.zoomLevel,
        min: Dimens.pianoRollMinZoom,
        max: Dimens.pianoRollMaxZoom,
        onChanged: (value) => notifier.setZoom(value),
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildBarCounter(BuildContext context, MusicStudioNotifier notifier) {
    final theme = Theme.of(context);
    final bars = notifier.value.bars;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              if (bars > 1) notifier.setBars(bars - 1);
            },
          ),
          Text('$bars Bars', style: theme.textTheme.bodySmall),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => notifier.setBars(bars + 1),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
