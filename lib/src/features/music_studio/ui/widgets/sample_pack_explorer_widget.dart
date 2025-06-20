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
    return Container(
      padding: EdgeInsets.all(Dimens.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                IconsaxPlusLinear.folder_2,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: Dimens.spacingSmall),
              Text(
                'Sample Packs',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: _addSamplePack,
                icon: const Icon(IconsaxPlusLinear.add),
                tooltip: 'Add Sample Pack',
              ),
            ],
          ),
          
          SizedBox(height: Dimens.spacingMedium),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            // Sample packs list
            Expanded(
              child: ListView.builder(
                itemCount: _samplePacks.length,
                itemBuilder: (context, index) {
                  return _buildSamplePackCard(_samplePacks[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSamplePackCard(SamplePack pack) {
    return Card(
      margin: EdgeInsets.only(bottom: Dimens.spacingMedium),
      child: ExpansionTile(
        leading: Icon(
          IconsaxPlusLinear.music_library_2,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          pack.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${pack.samples.length} samples',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(Dimens.paddingMedium),
            child: Column(
              children: pack.samples.map((sample) {
                return _buildSampleItem(sample, pack);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSampleItem(Sample sample, SamplePack pack) {
    return Consumer<MusicStudioNotifier>(builder: (context, notifier, child) {
      return Container(
        margin: EdgeInsets.only(bottom: Dimens.spacingSmall),
        child: Row(
          children: [
            Icon(
              IconsaxPlusLinear.music,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            SizedBox(width: Dimens.spacingSmall),
            Expanded(
              child: Text(
                sample.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              onPressed: () => _previewSample(sample),
              icon: const Icon(IconsaxPlusLinear.play),
              iconSize: 16,
              tooltip: 'Preview',
            ),
            IconButton(
              onPressed: () => _addSampleToTrack(notifier, sample),
              icon: const Icon(IconsaxPlusLinear.add_circle),
              iconSize: 16,
              tooltip: 'Add to Track',
            ),
          ],
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