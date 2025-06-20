import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:mstudio/src/core/theme/dimens.dart';
import 'package:mstudio/src/features/music_studio/models/sample_pack.dart';

class InstrumentSelectionDialog extends StatefulWidget {
  final List<SamplePack> samplePacks;
  final List<String> soundfonts;

  const InstrumentSelectionDialog({
    super.key,
    required this.samplePacks,
    required this.soundfonts,
  });

  @override
  State<InstrumentSelectionDialog> createState() =>
      _InstrumentSelectionDialogState();
}

class _InstrumentSelectionDialogState extends State<InstrumentSelectionDialog> {
  late final List<dynamic> _allInstruments;
  List<dynamic> _filteredInstruments = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Combine all instrument sources into a single list
    _allInstruments = [
      // A default synth option
      {'name': 'Default Synth', 'type': 'synth'},
      ...widget.soundfonts.map((sf) => {
            'name': sf.split('/').last.split('.').first,
            'path': sf,
            'type': 'soundfont'
          }),
      ...widget.samplePacks.expand((pack) => pack.samples).map((sample) => {
            'name': sample.name,
            'path': sample.path,
            'type': 'sample',
            'baseMidiNote': sample.baseMidiNote
          }),
    ];
    _filteredInstruments = _allInstruments;

    _searchController.addListener(() {
      _filterInstruments();
    });
  }

  void _filterInstruments() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredInstruments = _allInstruments;
      });
    } else {
      setState(() {
        _filteredInstruments = _allInstruments.where((inst) {
          final name = inst['name'] as String;
          return name.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Select Instrument', style: theme.textTheme.titleLarge),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search instruments...',
                prefixIcon: const Icon(IconsaxPlusLinear.search_normal_1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 102),
              ),
            ),
            const SizedBox(height: 16),

            // Instrument list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredInstruments.length,
                itemBuilder: (context, index) {
                  final instrument = _filteredInstruments[index];
                  return _buildInstrumentItem(instrument, theme);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildInstrumentItem(Map<String, dynamic> instrument, ThemeData theme) {
    IconData icon;
    switch (instrument['type']) {
      case 'synth':
        icon = IconsaxPlusLinear.keyboard;
        break;
      case 'soundfont':
        icon = IconsaxPlusLinear.music_filter;
        break;
      case 'sample':
        icon = IconsaxPlusLinear.music;
        break;
      default:
        icon = IconsaxPlusLinear.box;
    }

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(instrument['name'], style: theme.textTheme.bodyLarge),
      onTap: () {
        // Return the selected instrument
        Navigator.of(context).pop(instrument);
      },
    );
  }
}
