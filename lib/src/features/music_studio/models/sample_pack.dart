import 'package:equatable/equatable.dart';

class SamplePack extends Equatable {
  final String id;
  final String name;
  final String path;
  final List<Sample> samples;
  
  const SamplePack({
    required this.id,
    required this.name,
    required this.path,
    required this.samples,
  });
  
  SamplePack copyWith({
    String? id,
    String? name,
    String? path,
    List<Sample>? samples,
  }) {
    return SamplePack(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      samples: samples ?? this.samples,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'samples': samples.map((sample) => sample.toJson()).toList(),
    };
  }

  factory SamplePack.fromJson(Map<String, dynamic> json) {
    return SamplePack(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      samples: (json['samples'] as List)
          .map((sampleJson) => Sample.fromJson(sampleJson as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, path, samples];
}

class Sample extends Equatable {
  final String name;
  final String path;
  final String? description;
  final List<String>? tags;
  
  const Sample({
    required this.name,
    required this.path,
    this.description,
    this.tags,
  });
  
  Sample copyWith({
    String? name,
    String? path,
    String? description,
    List<String>? tags,
  }) {
    return Sample(
      name: name ?? this.name,
      path: path ?? this.path,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'description': description,
      'tags': tags,
    };
  }

  factory Sample.fromJson(Map<String, dynamic> json) {
    return Sample(
      name: json['name'] as String,
      path: json['path'] as String,
      description: json['description'] as String?,
      tags: (json['tags'] as List?)?.cast<String>(),
    );
  }

  @override
  List<Object?> get props => [name, path, description, tags];
}