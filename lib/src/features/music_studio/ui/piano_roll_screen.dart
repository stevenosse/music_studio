import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mstudio/src/shared/locator.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:auto_route/auto_route.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/i18n/l10n.dart';
import '../logic/music_studio_notifier.dart';
import '../logic/piano_roll/piano_roll_notifier.dart';
import '../models/note.dart';
import 'widgets/piano_roll/piano_roll_grid_widget.dart';
import 'widgets/piano_roll/piano_roll_keyboard_widget.dart';
import 'widgets/piano_roll/piano_roll_header_widget.dart';
import 'widgets/piano_roll/piano_roll_toolbar_widget.dart';
import 'widgets/piano_roll/piano_roll_velocity_editor_widget.dart';

@RoutePage()
class PianoRollScreen extends StatefulWidget implements AutoRouteWrapper {
  final int trackIndex;

  const PianoRollScreen({
    super.key,
    required this.trackIndex,
  });

  @override
  Widget wrappedRoute(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locator<MusicStudioNotifier>()),
        ChangeNotifierProvider(
          create: (context) => PianoRollNotifier(context.read<MusicStudioNotifier>()),
        ),
      ],
      child: this,
    );
  }

  @override
  State<PianoRollScreen> createState() => _PianoRollScreenState();
}

class _PianoRollScreenState extends State<PianoRollScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _pianoScrollController = ScrollController();

  bool _isUpdatingVerticalScroll = false;
  bool _isUpdatingPianoScroll = false;
  final FocusNode _focusNode = FocusNode();
  VoidCallback? _playbackListener;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _setupScrollControllers();
      _setupPlaybackListener();
    });
  }

  void _setupPlaybackListener() {
    final musicStudioNotifier = context.read<MusicStudioNotifier>();
    final pianoRollNotifier = context.read<PianoRollNotifier>();

    _playbackListener = () {
      if (!mounted) return;
      final playheadPosition = musicStudioNotifier.value.currentStep.toDouble();
      pianoRollNotifier.setPlayheadPosition(playheadPosition);
    };

    musicStudioNotifier.addListener(_playbackListener!);
  }

  void _setupScrollControllers() {
    // Sync vertical scroll between piano keyboard and grid
    _verticalScrollController.addListener(() {
      if (_isUpdatingVerticalScroll) return;

      if (_pianoScrollController.hasClients) {
        _isUpdatingPianoScroll = true;
        // Sync scroll positions directly without inversion
        final maxScrollExtent =
            _verticalScrollController.position.maxScrollExtent;
        final pianoMaxScrollExtent =
            _pianoScrollController.position.maxScrollExtent;

        if (maxScrollExtent > 0 && pianoMaxScrollExtent > 0) {
          final normalizedOffset =
              _verticalScrollController.offset / maxScrollExtent;
          final targetOffset = pianoMaxScrollExtent * normalizedOffset;
          _pianoScrollController.jumpTo(targetOffset);
        }
        _isUpdatingPianoScroll = false;
      }
      context
          .read<PianoRollNotifier>()
          .setVerticalScroll(_verticalScrollController.offset);
    });

    // Sync piano keyboard scroll back to grid
    _pianoScrollController.addListener(() {
      if (_isUpdatingPianoScroll) return;

      if (_verticalScrollController.hasClients) {
        _isUpdatingVerticalScroll = true;
        // Sync scroll positions directly without inversion
        final pianoMaxScrollExtent =
            _pianoScrollController.position.maxScrollExtent;
        final maxScrollExtent =
            _verticalScrollController.position.maxScrollExtent;

        if (pianoMaxScrollExtent > 0 && maxScrollExtent > 0) {
          final normalizedOffset =
              _pianoScrollController.offset / pianoMaxScrollExtent;
          final targetOffset = maxScrollExtent * normalizedOffset;
          _verticalScrollController.jumpTo(targetOffset);
        }
        _isUpdatingVerticalScroll = false;
      }
    });

    _horizontalScrollController.addListener(() {
      if (_horizontalScrollController.hasClients) {
        context
            .read<PianoRollNotifier>()
            .setHorizontalScroll(_horizontalScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _pianoScrollController.dispose();
    if (_playbackListener != null) {
      locator<MusicStudioNotifier>().removeListener(_playbackListener!);
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = I18n.of(context);

    return Consumer2<MusicStudioNotifier, PianoRollNotifier>(
      builder:
          (context, musicStudioNotifierFromBuilder, pianoRollNotifier, child) {
        final musicStudioNotifier = context.watch<MusicStudioNotifier>();

        final currentMusicValue = musicStudioNotifier.value;
        final pianoRollState = pianoRollNotifier.value;

        if (widget.trackIndex >= currentMusicValue.tracks.length) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.pianoRoll_title),
            ),
            body: Center(
              child: Text(
                  'Track not found: trackIndex ${widget.trackIndex} >= tracks.length ${currentMusicValue.tracks.length}'),
            ),
          );
        }
        final track = currentMusicValue.tracks[widget.trackIndex];
        final notes = track.notes;

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) =>
              _handleKeyEvent(event, musicStudioNotifier, notes),
          child: Scaffold(
            appBar: _buildAppBar(context, l10n, track, musicStudioNotifier),
            body: Column(
              children: [
                // Toolbar
                PianoRollToolbarWidget(
                  onQuantize: () =>
                      _quantizeSelectedNotes(musicStudioNotifier, notes),
                  onZoomIn: pianoRollNotifier.zoomIn,
                  onZoomOut: pianoRollNotifier.zoomOut,
                  onZoomFit: () => pianoRollNotifier.setZoom(1.0),
                ),

                // Main piano roll area
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left side: Piano Keyboard
                      SizedBox(
                        width: Dimens.pianoRollKeyboardWidth,
                        child: Column(
                          children: [
                            SizedBox(height: Dimens.pianoRollHeaderHeight), // Spacer for header
                            Expanded(
                              child: PianoRollKeyboardWidget(
                                verticalScrollController: _pianoScrollController,
                                onKeyPressed: (pitch) =>
                                    _previewNote(musicStudioNotifier, pitch),
                                totalKeys: pianoRollState.totalKeys,
                                lowestNote: pianoRollState.lowestNote,
                              ),
                            ),
                            if (pianoRollState.showVelocityEditor)
                              SizedBox(height: Dimens.pianoRollVelocityBarHeight),
                          ],
                        ),
                      ),
                      // Right side: Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: pianoRollNotifier.totalWidth,
                            child: Column(
                              children: [
                                // Header
                                SizedBox(
                                  height: Dimens.pianoRollHeaderHeight,
                                  child: PianoRollHeaderWidget(
                                    cellWidth: pianoRollNotifier.cellWidth,
                                    totalSteps: pianoRollNotifier.totalSteps,
                                    stepsPerBar: pianoRollNotifier.stepsPerBar,
                                    onSeek: (position) =>
                                        _seek(musicStudioNotifier, position),
                                  ),
                                ),
                                // Grid
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _verticalScrollController,
                                    physics: const ClampingScrollPhysics(),
                                    child: PianoRollGridWidget(
                                      trackIndex: widget.trackIndex,
                                      track: track,
                                      stepsPerBar: pianoRollNotifier.stepsPerBar,
                                    ),
                                  ),
                                ),
                                // Velocity editor
                                if (pianoRollState.showVelocityEditor)
                                  SizedBox(
                                    height: Dimens.pianoRollVelocityBarHeight,
                                    child: PianoRollVelocityEditorWidget(
                                      notes: notes,
                                      cellWidth:
                                          40.0 * pianoRollState.zoomLevel,
                                      totalSteps: pianoRollNotifier.totalSteps,
                                      onVelocityChanged: (note, velocity) =>
                                          _updateNoteVelocity(
                                              musicStudioNotifier,
                                              note.id,
                                              velocity),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    I18n l10n,
    track,
    MusicStudioNotifier musicStudioNotifier,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: track.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: Dimens.spacingSmall),
          Text('${track.name} - ${l10n.pianoRoll_title}'),
        ],
      ),
      actions: [
        // Transport controls
        IconButton(
          onPressed: () {
            if (musicStudioNotifier.isPlaying) {
              musicStudioNotifier.pause();
            } else {
              musicStudioNotifier.play();
            }
          },
          icon: Icon(
            musicStudioNotifier.isPlaying
                ? IconsaxPlusLinear.pause
                : IconsaxPlusLinear.play,
          ),
          tooltip: musicStudioNotifier.isPlaying
              ? l10n.pianoRoll_pause
              : l10n.pianoRoll_play,
        ),
        IconButton(
          onPressed: () => musicStudioNotifier.stop(),
          icon: const Icon(IconsaxPlusLinear.stop),
          tooltip: l10n.pianoRoll_stop,
        ),

        const VerticalDivider(),

        // Zoom controls
        Consumer<PianoRollNotifier>(
          builder: (context, notifier, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: notifier.zoomOut,
                  icon: const Icon(IconsaxPlusLinear.minus),
                  tooltip: l10n.pianoRoll_zoomOut,
                ),
                Text('${(notifier.value.zoomLevel * 100).round()}%'),
                IconButton(
                  onPressed: notifier.zoomIn,
                  icon: const Icon(IconsaxPlusLinear.add),
                  tooltip: l10n.pianoRoll_zoomIn,
                ),
              ],
            );
          },
        ),

        SizedBox(width: Dimens.spacingMedium),
      ],
    );
  }



  KeyEventResult _handleKeyEvent(
    KeyEvent event,
    MusicStudioNotifier musicStudioNotifier,
    List<Note> notes,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Delete selected notes
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (context.read<PianoRollNotifier>().hasSelectedNotes()) {
        _deleteSelectedNotes(musicStudioNotifier);
        return KeyEventResult.handled;
      }
    }

    // Escape to deselect all
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      context.read<PianoRollNotifier>().deselectAllNotes();
      return KeyEventResult.handled;
    }

    // Ctrl+A to select all
    if (event.logicalKey == LogicalKeyboardKey.keyA &&
        HardwareKeyboard.instance.isControlPressed) {
      context.read<PianoRollNotifier>().selectAllNotes(notes);
      return KeyEventResult.handled;
    }

    // Space to play/pause
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (musicStudioNotifier.isPlaying) {
        musicStudioNotifier.pause();
      } else {
        musicStudioNotifier.play();
      }
      return KeyEventResult.handled;
    }

    // Arrow keys to move selected notes
    if (context.read<PianoRollNotifier>().hasSelectedNotes()) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _moveSelectedNotes(musicStudioNotifier, const Offset(-1, 0));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _moveSelectedNotes(musicStudioNotifier, const Offset(1, 0));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveSelectedNotes(musicStudioNotifier, const Offset(0, 1));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveSelectedNotes(musicStudioNotifier, const Offset(0, -1));
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _deleteSelectedNotes(MusicStudioNotifier musicStudioNotifier) {
    final selectedNoteIds =
        context.read<PianoRollNotifier>().value.selectedNotes;
    musicStudioNotifier.deleteMultipleNotes(selectedNoteIds.toList());
    context.read<PianoRollNotifier>().deselectAllNotes();
  }

  void _updateNoteVelocity(
      MusicStudioNotifier musicStudioNotifier, String noteId, int velocity) {
    final track = musicStudioNotifier.value.tracks[widget.trackIndex];
    final note = track.notes.firstWhere((n) => n.id == noteId);
    final updatedNote = note.copyWith(velocity: velocity);
    musicStudioNotifier.updateNote(updatedNote);
  }

  void _seek(MusicStudioNotifier musicStudioNotifier, double position) {
    musicStudioNotifier.audioService.seekToStep(position.round());
  }

  void _moveSelectedNotes(
      MusicStudioNotifier musicStudioNotifier, Offset delta) {
    final pianoRollNotifier = context.read<PianoRollNotifier>();
    final track = musicStudioNotifier.value.tracks[widget.trackIndex];
    final selectedNotes =
        track.notes.where((n) => pianoRollNotifier.isNoteSelected(n.id));

    final updatedNotes = <Note>[];
    for (final note in selectedNotes) {
      final newStep = pianoRollNotifier
          .snapToGrid(note.step.toDouble() + delta.dx.round());
      final newPitch = (note.pitch + delta.dy.round()).clamp(0, 127);

      updatedNotes.add(note.copyWith(
        step: newStep
            .round()
            .clamp(0, pianoRollNotifier.totalSteps - note.duration),
        pitch: newPitch,
      ));
    }
    musicStudioNotifier.updateMultipleNotes(updatedNotes);
  }

  void _quantizeSelectedNotes(
      MusicStudioNotifier musicStudioNotifier, List<Note> notes) {
    final pianoRollNotifier = context.read<PianoRollNotifier>();
    final selectedNotes =
        notes.where((n) => pianoRollNotifier.isNoteSelected(n.id));

    final updatedNotes = <Note>[];
    for (final note in selectedNotes) {
      updatedNotes.add(pianoRollNotifier.quantizeNote(note));
    }
    musicStudioNotifier.updateMultipleNotes(updatedNotes);
  }

  void _previewNote(MusicStudioNotifier musicStudioNotifier, int pitch) {
    final track = musicStudioNotifier.value.tracks[widget.trackIndex];
    musicStudioNotifier.audioService
        .playTrackSample(track.id, pitch: pitch, volume: 1.0);
  }
}
