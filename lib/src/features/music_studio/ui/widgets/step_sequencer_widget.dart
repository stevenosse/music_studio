import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:mstudio/src/core/routing/app_router.dart';
import 'package:mstudio/src/features/music_studio/logic/music_studio_state.dart';
import 'package:mstudio/src/features/music_studio/models/note.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/dimens.dart';
import '../../logic/music_studio_notifier.dart';


import 'sample_pack_explorer_widget.dart';

class StepSequencerWidget extends StatefulWidget {
  const StepSequencerWidget({super.key});

  @override
  State<StepSequencerWidget> createState() => _StepSequencerWidgetState();
}

class _StepSequencerWidgetState extends State<StepSequencerWidget> {
  Widget _buildNoteWidget(BuildContext context, Note note, Color color, {bool isDragging = false}) {
    return Opacity(
      opacity: isDragging ? 0.7 : 1.0,
      child: Container(
        width: note.duration * 24.0,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            note.pitch.toString(), // Or some other note representation
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  Color _getStepColor(BuildContext context, bool isActive, Color trackColor, bool isCurrentStep, bool isDragTarget) {
    if (isCurrentStep) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.4);
    }
    if (isActive) {
      return trackColor;
    }
    if (isDragTarget) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
    }
    return Theme.of(context).colorScheme.surface.withValues(alpha: 0.3);
  }

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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Step Sequencer',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '32 Steps',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: Dimens.spacingMedium),
                              _buildStepNumbers(context, state),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showSamplePackExplorer =
                                  !_showSamplePackExplorer;
                            });
                          },
                          icon: Icon(_showSamplePackExplorer
                              ? Icons.close
                              : Icons.library_music),
                          label:
                              Text(_showSamplePackExplorer ? 'Close' : 'Packs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showSamplePackExplorer
                                ? Colors.red
                                : Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Dimens.spacingSmall),

                    // Track rows
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.tracks.length,
                        itemBuilder: (context, trackIndex) {
                          return _buildTrackRow(
                              context, notifier, state, trackIndex);
                        },
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
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
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

  Widget _buildStepNumbers(BuildContext context, state) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Track name column spacer
          SizedBox(width: 100),

          // Step numbers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 32 * 24.0, // Match step buttons width
                child: Row(
                  children: List.generate(32, (index) {
                    final stepNumber = index + 1;
                    final isCurrentStep =
                        index == state.currentStep && state.isPlaying;
                    final isBarStart = index % 4 == 0;

                    return SizedBox(
                      width: 24,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          color: isCurrentStep
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3)
                              : isBarStart
                                  ? Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.5)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                          border: isBarStart
                              ? Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            stepNumber.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  fontWeight: isCurrentStep
                                      ? FontWeight.bold
                                      : isBarStart
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color: isCurrentStep
                                      ? Theme.of(context).colorScheme.primary
                                      : isBarStart
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.9)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackRow(BuildContext context, MusicStudioNotifier notifier,
      MusicStudioState state, int trackIndex) {
    final track = state.tracks[trackIndex];
    final isSelected = trackIndex == state.selectedTrackIndex;

    return Container(
      margin: EdgeInsets.only(bottom: Dimens.spacingSmall),
      child: Row(
        children: [
          // Track name and controls
          SizedBox(
            width: 100,
            child: GestureDetector(
              onTap: () => notifier.selectTrack(trackIndex),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimens.paddingSmall,
                  vertical: Dimens.paddingXSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? track.color.withValues(alpha: 0.2)
                      : track.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimens.radiusXSmall),
                  border: Border.all(
                    color: isSelected
                        ? track.color
                        : track.color.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        // Mute indicator
                        if (track.isMuted)
                          Icon(
                            IconsaxPlusLinear.volume_slash,
                            size: 10,
                            color: Colors.red,
                          ),
                        // Solo indicator
                        if (track.isSolo)
                          Icon(
                            IconsaxPlusLinear.headphone,
                            size: 10,
                            color: Colors.orange,
                          ),
                        const Spacer(),
                        // Piano roll button
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => context.router.push(PianoRollRoute(trackIndex: trackIndex)),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  IconsaxPlusLinear.music,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    // Volume slider
                    SizedBox(
                      height: 20,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: track.volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: track.color,
                          inactiveColor: track.color.withValues(alpha: 0.3),
                          onChanged: (value) {
                            notifier.setTrackVolume(trackIndex, value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: Dimens.spacingSmall),

          // Step buttons with horizontal scrolling
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 32 * 24.0, // 32 steps * 24 pixels each
                  child: Row(
                    children: List.generate(32, (stepIndex) {

                      final isCurrentStep =
                          stepIndex == state.currentStep && state.isPlaying;
                      final isBarStart = stepIndex % 4 == 0;
                      final isBarEnd = stepIndex % 4 == 3;

                      final note = notifier.getNoteAt(trackIndex, stepIndex);

                      return SizedBox(
                        width: 24,
                        child: DragTarget<Note>(
                          onWillAcceptWithDetails: (data) => true,
                          onAcceptWithDetails: (details) {
                            final newNote = details.data.copyWith(step: stepIndex, trackIndex: trackIndex);
                            notifier.updateNote(newNote);
                          },
                          builder: (context, candidateData, rejectedData) {
                            if (note != null) {
                              return LongPressDraggable<Note>(
                                data: note,
                                feedback: _buildNoteWidget(context, note, track.color, isDragging: true),
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    final newDuration = (note.duration + details.delta.dx / 24.0).round();
                                    if (newDuration > 0) {
                                      notifier.updateNote(note.copyWith(duration: newDuration));
                                    }
                                  },
                                  onSecondaryTap: () {
                                    notifier.removeNote(note);
                                  },
                                  child: _buildNoteWidget(context, note, track.color),
                                ),
                              );
                            }
                            return GestureDetector(
                              onTap: () {
                                if (note == null) {
                                  notifier.addNote(Note(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    trackIndex: trackIndex,
                                    step: stepIndex,
                                    duration: 1,
                                    pitch: 72,
                                    velocity: 100,
                                    color: track.color,
                                  ));
                                } else {
                                  notifier.removeNote(note);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getStepColor(
                                      context, note != null, track.color, isCurrentStep, candidateData.isNotEmpty),
                                  border: Border(
                                    left: isBarStart
                                        ? BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          )
                                        : BorderSide.none,
                                    right: isBarEnd
                                        ? BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: 0.2),
                                            width: 1,
                                          )
                                        : BorderSide.none,
                                    top: isCurrentStep
                                        ? BorderSide(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                    bottom: isCurrentStep
                                        ? BorderSide(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                child: note != null
                                    ? Center(
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
