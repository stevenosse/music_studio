import 'package:flutter/material.dart';
import 'package:mstudio/src/features/music_studio/logic/piano_roll/piano_roll_notifier.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/dimens.dart';

class PianoRollKeyboardWidget extends StatelessWidget {
  final ScrollController verticalScrollController;
  final Function(int) onKeyPressed;
  final int totalKeys;
  final int lowestNote;

  const PianoRollKeyboardWidget({
    super.key,
    required this.verticalScrollController,
    required this.onKeyPressed,
    required this.totalKeys,
    required this.lowestNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.pianoRollKeyboardWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: verticalScrollController,
          child: Column(
            children: List.generate(
              totalKeys,
              (index) => _buildPianoKey(
                context,
                totalKeys - 1 - index + lowestNote,
                index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPianoKey(BuildContext context, int midiNote, int index) {
    final theme = Theme.of(context);
    final isBlackKey = _isBlackKey(midiNote);
    final isC = (midiNote % 12) == 0;
    
    return Consumer<PianoRollNotifier>(
      builder: (context, notifier, child) {
        final isHighlighted = false;
        
        return GestureDetector(
          onTap: () => onKeyPressed(midiNote),
          child: Container(
            height: Dimens.pianoRollKeyHeight,
            decoration: BoxDecoration(
              color: _getKeyColor(theme, isBlackKey, isHighlighted),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                top: isC
                    ? BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      )
                    : BorderSide.none,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Key color indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isBlackKey ? Colors.black : Colors.white,
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Note label
                  Expanded(
                    child: Text(
                      _getNoteLabel(midiNote),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTextColor(theme, isBlackKey),
                        fontSize: 11,
                        fontWeight: isC ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  
                  // MIDI note number (for C notes)
                  if (isC)
                    Text(
                      midiNote.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isBlackKey(int midiNote) {
    const blackKeyPattern = [1, 3, 6, 8, 10]; // C#, D#, F#, G#, A#
    return blackKeyPattern.contains(midiNote % 12);
  }

  Color _getKeyColor(ThemeData theme, bool isBlackKey, bool isHighlighted) {
    if (isHighlighted) {
      return theme.colorScheme.primary.withValues(alpha: 0.3);
    }
    
    if (isBlackKey) {
      return theme.colorScheme.surface.withValues(alpha: 0.7);
    }
    
    return theme.colorScheme.surface;
  }

  Color _getTextColor(ThemeData theme, bool isBlackKey) {
    if (isBlackKey) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.8);
    }
    return theme.colorScheme.onSurface;
  }

  String _getNoteLabel(int midiNote) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final noteName = noteNames[midiNote % 12];
    final octave = (midiNote / 12).floor() - 1;
    return '$noteName$octave';
  }
}