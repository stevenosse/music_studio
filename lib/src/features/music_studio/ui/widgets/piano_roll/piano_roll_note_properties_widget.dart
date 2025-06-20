import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/note.dart';

class PianoRollNotePropertiesWidget extends StatefulWidget {
  final List<Note> selectedNotes;
  final Function(Note, Note) onNoteUpdated;

  const PianoRollNotePropertiesWidget({
    super.key,
    required this.selectedNotes,
    required this.onNoteUpdated,
  });

  @override
  State<PianoRollNotePropertiesWidget> createState() =>
      _PianoRollNotePropertiesWidgetState();
}

class _PianoRollNotePropertiesWidgetState
    extends State<PianoRollNotePropertiesWidget> {
  final _pitchController = TextEditingController();
  final _stepController = TextEditingController();
  final _durationController = TextEditingController();
  final _velocityController = TextEditingController();

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(PianoRollNotePropertiesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedNotes != widget.selectedNotes) {
      _updateControllers();
    }
  }

  @override
  void dispose() {
    _pitchController.dispose();
    _stepController.dispose();
    _durationController.dispose();
    _velocityController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    if (_isUpdating) return;

    if (widget.selectedNotes.isEmpty) {
      _pitchController.clear();
      _stepController.clear();
      _durationController.clear();
      _velocityController.clear();
      return;
    }

    final firstNote = widget.selectedNotes.first;

    if (widget.selectedNotes.length == 1) {
      // Single note selected - show exact values
      _pitchController.text = _getNoteLabel(firstNote.pitch);
      _stepController.text = firstNote.step.toString();
      _durationController.text = firstNote.duration.toString();
      _velocityController.text = firstNote.velocity.toString();
    } else {
      // Multiple notes selected - show mixed values or common values
      _pitchController.text = _getMixedValue(
        widget.selectedNotes.map((n) => n.pitch).toSet(),
        (pitch) => _getNoteLabel(pitch),
      );
      _stepController.text = _getMixedValue(
        widget.selectedNotes.map((n) => n.step).toSet(),
        (step) => step.toString(),
      );
      _durationController.text = _getMixedValue(
        widget.selectedNotes.map((n) => n.duration).toSet(),
        (duration) => duration.toString(),
      );
      _velocityController.text = _getMixedValue(
        widget.selectedNotes.map((n) => n.velocity).toSet(),
        (velocity) => velocity.toString(),
      );
    }
  }

  String _getMixedValue<T>(Set<T> values, String Function(T) formatter) {
    if (values.length == 1) {
      return formatter(values.first);
    }
    return 'Mixed';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.selectedNotes.isEmpty) {
      return Container(
        width: 250,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            left: BorderSide(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: Text(
            'No notes selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.music_note,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.selectedNotes.length == 1
                      ? 'Note Properties'
                      : '${widget.selectedNotes.length} Notes Selected',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Properties
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyField(
                    context,
                    label: 'Pitch',
                    controller: _pitchController,
                    onChanged: _onPitchChanged,
                    readOnly: true,
                  ),

                  const SizedBox(height: 16),

                  _buildPropertyField(
                    context,
                    label: 'Start Time',
                    controller: _stepController,
        onChanged: _onStepChanged,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildPropertyField(
                    context,
                    label: 'Duration',
                    controller: _durationController,
                    onChanged: _onDurationChanged,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildPropertyField(
                    context,
                    label: 'Velocity',
                    controller: _velocityController,
                    onChanged: _onVelocityChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickActionButton(
              context,
              label: '+12',
              tooltip: 'Transpose up one octave',
              onPressed: () => _transposeNotes(12),
            ),
            _buildQuickActionButton(
              context,
              label: '-12',
              tooltip: 'Transpose down one octave',
              onPressed: () => _transposeNotes(-12),
            ),
            _buildQuickActionButton(
              context,
              label: '×2',
              tooltip: 'Double duration',
              onPressed: () => _scaleDuration(2.0),
            ),
            _buildQuickActionButton(
              context,
              label: '÷2',
              tooltip: 'Half duration',
              onPressed: () => _scaleDuration(0.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  void _onPitchChanged(String value) {
    // Pitch is read-only for now
  }

  void _onStepChanged(String value) {
    final step = int.tryParse(value);
    if (step != null && step >= 0) {
      _updateNotes((note) => note.copyWith(step: step));
    }
  }

  void _onDurationChanged(String value) {
    final duration = int.tryParse(value);
    if (duration != null && duration > 0) {
      _updateNotes((note) => note.copyWith(duration: duration));
    }
  }

  void _onVelocityChanged(String value) {
    final velocity = int.tryParse(value);
    if (velocity != null && velocity >= 1 && velocity <= 127) {
      _updateNotes((note) => note.copyWith(velocity: velocity));
    }
  }

  void _transposeNotes(int semitones) {
    _updateNotes((note) {
      final newPitch = (note.pitch + semitones).clamp(0, 127);
      return note.copyWith(pitch: newPitch);
    });
  }

  void _scaleDuration(double factor) {
    _updateNotes((note) {
      final newDuration = (note.duration * factor).round().clamp(1, 16);
      return note.copyWith(duration: newDuration);
    });
  }

  void _updateNotes(Note Function(Note) updater) {
    _isUpdating = true;

    for (final note in widget.selectedNotes) {
      final updatedNote = updater(note);
      widget.onNoteUpdated(note, updatedNote);
    }

    // Update controllers after a brief delay to avoid conflicts
    Future.delayed(const Duration(milliseconds: 100), () {
      _isUpdating = false;
      _updateControllers();
    });
  }

  String _getNoteLabel(int midiNote) {
    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final noteName = noteNames[midiNote % 12];
    final octave = (midiNote / 12).floor() - 1;
    return '$noteName$octave';
  }
}
