import 'package:flutter/material.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_notifier.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_state.dart';
import 'package:provider/provider.dart';

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
        builder: (context, notifier, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Mode toggle
                _buildModeToggle(context, notifier),

                const SizedBox(width: 16),

                // Snap settings
                _buildSnapSettings(context, notifier),

                const SizedBox(width: 16),

                // Quantize button
                _buildQuantizeButton(context),

                const Spacer(),

                // Zoom controls
                _buildZoomControls(context, notifier),

                const SizedBox(width: 16),

                // Zoom level indicator
                _buildZoomIndicator(context, notifier),
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
          _buildModeButton(
            context,
            icon: Icons.edit,
            label: 'Draw',
            isSelected: notifier.value.mode == PianoRollMode.draw,
            onPressed: () => notifier.setMode(PianoRollMode.draw),
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.dividerColor,
          ),
          _buildModeButton(
            context,
            icon: Icons.mouse,
            label: 'Select',
            isSelected: notifier.value.mode == PianoRollMode.select,
            onPressed: () => notifier.setMode(PianoRollMode.select),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
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

  Widget _buildSnapSettings(BuildContext context, PianoRollNotifier notifier) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Snap toggle
        IconButton(
          onPressed: () => notifier.toggleSnap(),
          icon: Icon(
            notifier.value.snapResolution != SnapResolution.none
                ? Icons.grid_on
                : Icons.grid_off,
            color: notifier.value.snapResolution != SnapResolution.none
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          tooltip: 'Snap to Grid',
        ),

        // Snap resolution dropdown
        if (notifier.value.snapResolution != SnapResolution.none)
          DropdownButton<SnapResolution>(
            value: notifier.value.snapResolution,
            onChanged: (value) {
              if (value != null) {
                notifier.setSnapResolution(value);
              }
            },
            underline: const SizedBox(),
            items: SnapResolution.values
                .where((res) => res != SnapResolution.none)
                .map((resolution) => DropdownMenuItem(
                      value: resolution,
                      child: Text(
                        _getSnapResolutionLabel(resolution),
                        style: theme.textTheme.bodySmall,
                      ),
                    ))
                .toList(),
          ),
      ],
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

  String _getSnapResolutionLabel(SnapResolution resolution) {
    switch (resolution) {
      case SnapResolution.quarter:
        return '1/4';
      case SnapResolution.eighth:
        return '1/8';
      case SnapResolution.sixteenth:
        return '1/16';
      case SnapResolution.thirtySecond:
        return '1/32';
      case SnapResolution.triplets:
        return 'Triplets';
      case SnapResolution.none:
        return 'None';
    }
  }
}