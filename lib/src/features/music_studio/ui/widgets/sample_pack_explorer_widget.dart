import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../shared/locator.dart';
import '../../../../shared/services/storage/storage.dart';
import '../../logic/music_studio_notifier.dart';
import '../../models/sample_pack.dart';

class SamplePackExplorerWidget extends StatefulWidget {
  final Function(String sampleName, String samplePath) onSampleSelected;
  
  const SamplePackExplorerWidget({
    super.key,
    required this.onSampleSelected,
  });

  @override
  State<SamplePackExplorerWidget> createState() => _SamplePackExplorerWidgetState();
}

class _SamplePackExplorerWidgetState extends State<SamplePackExplorerWidget> {
  List<SamplePack> _samplePacks = [];
  bool _isLoading = false;
  final Storage _storage = locator<Storage>();
  
  @override
  void initState() {
    super.initState();
    _loadSamplePacks();
  }
  
  Future<void> _loadSamplePacks() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load built-in sample packs
      _samplePacks = [
        SamplePack(
          id: 'default_drums',
          name: 'Default Drums',
          path: 'assets/samples',
          samples: [
            Sample(name: 'Kick', path: 'assets/samples/[SAINT6] Ronny Kick.wav'),
            Sample(name: 'Snare', path: 'assets/samples/[SAINT6] Pop Snare 1.wav'),
            Sample(name: 'Clap', path: 'assets/samples/[SAINT6] Bounce Clap.wav'),
            Sample(name: 'Hi-Hat', path: 'assets/samples/[SAINT6] 808 Hi Hat 1.wav'),
          ],
        ),
      ];
      
      // Load persisted sample pack paths
      final persistedPaths = await _storage.read<List<String>>(key: 'sample_pack_paths') ?? [];
      for (final path in persistedPaths) {
        final directory = Directory(path);
        if (await directory.exists()) {
          final pack = await _scanDirectoryForSamples(directory);
          if (pack != null) {
            _samplePacks.add(pack);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading sample packs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 8.0, right: 8.0),
          child: Row(
            children: [
              Icon(
                IconsaxPlusLinear.folder_2,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sample Packs',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton.filled(
                  onPressed: _addSamplePack,
                  icon: const Icon(IconsaxPlusLinear.add),
                  iconSize: 16,
                  tooltip: 'Add Sample Pack',
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimens.radiusSmall),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sample packs list
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: ListView.builder(
              itemCount: _samplePacks.length,
              itemBuilder: (context, index) {
                return _buildSamplePackCard(_samplePacks[index]);
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildSamplePackCard(SamplePack pack) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 102),
        borderRadius: BorderRadius.circular(Dimens.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 51),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          IconsaxPlusLinear.music_library_2,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          pack.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${pack.samples.length} samples',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 179)),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: pack.samples.map((sample) {
          return _buildSampleItem(sample, pack);
        }).toList(),
      ),
    );
  }
  
  Widget _buildSampleItem(Sample sample, SamplePack pack) {
    final theme = Theme.of(context);
    return Consumer<MusicStudioNotifier>(builder: (context, notifier, child) {
      return InkWell(
        onTap: () => _addSampleToTrack(notifier, sample),
        borderRadius: BorderRadius.circular(Dimens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Icon(
                IconsaxPlusLinear.music,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 179),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sample.name,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 28,
                width: 28,
                child: IconButton(
                  onPressed: () => _previewSample(sample),
                  icon: const Icon(IconsaxPlusLinear.play),
                  iconSize: 16,
                  tooltip: 'Preview',
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Future<SamplePack?> _scanDirectoryForSamples(Directory directory) async {
    final samples = <Sample>[];
    int fileCount = 0;
    const maxFiles = 500; // Limit to prevent memory issues
    
    try {
      // Recursively scan directory and subdirectories with limits
      await for (final entity in directory.list(recursive: true)) {
        if (fileCount >= maxFiles) {
          debugPrint('Reached maximum file limit ($maxFiles) for sample pack');
          break;
        }
        
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (['wav', 'mp3', 'aiff', 'flac', 'm4a', 'ogg'].contains(extension)) {
            final name = entity.path.split('/').last.split('.').first;
            samples.add(Sample(name: name, path: entity.path));
            fileCount++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${directory.path}: $e');
      return null;
    }
    
    if (samples.isNotEmpty) {
      final packName = directory.path.split('/').last;
      return SamplePack(
        id: 'pack_${DateTime.now().millisecondsSinceEpoch}',
        name: packName,
        path: directory.path,
        samples: samples,
      );
    }
    
    return null;
  }
  
  Future<void> _addSamplePack() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Let user select a folder
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scanning directory for audio files...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        final directory = Directory(selectedDirectory);
        
        // Check if directory exists and is accessible
        if (!await directory.exists()) {
          throw Exception('Selected directory does not exist');
        }
        
        final pack = await _scanDirectoryForSamples(directory);
        
        if (pack != null && pack.samples.isNotEmpty) {
          setState(() {
            _samplePacks.add(pack);
          });
          
          // Persist the path with error handling
          try {
            final currentPaths = await _storage.read<List<String>>(key: 'sample_pack_paths') ?? [];
            if (!currentPaths.contains(selectedDirectory)) {
              currentPaths.add(selectedDirectory);
              await _storage.writeStringList(key: 'sample_pack_paths', value: currentPaths);
            }
          } catch (storageError) {
            debugPrint('Failed to persist sample pack path: $storageError');
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added pack "${pack.name}" with ${pack.samples.length} samples'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No audio files found in selected folder'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _addSamplePack: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sample pack: ${e.toString().length > 100 ? "${e.toString().substring(0, 100)}..." : e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _previewSample(Sample sample) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preview: ${sample.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _addSampleToTrack(MusicStudioNotifier notifier, Sample sample) {
    // Add a new track with this sample
    notifier.addTrackWithSample(sample.name, sample.path);
    widget.onSampleSelected(sample.name, sample.path);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${sample.name}" to new track'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}