import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardStack {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<String> flashcardIds;
  final String? imageUrl;

  FlashcardStack({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.flashcardIds,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toUtc().toIso8601String(),
      'flashcard_ids': flashcardIds,
      'image_url': imageUrl,
    };
  }

  factory FlashcardStack.fromMap(Map<String, dynamic> map) {
    return FlashcardStack(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      createdAt: (map['created_at'] is Timestamp)
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.parse(map['created_at'] as String),
      flashcardIds: List<String>.from(map['flashcard_ids'] ?? []),
      imageUrl: map['image_url'] as String?,
    );
  }

  FlashcardStack copyWith({
    String? name,
    String? description,
    List<String>? flashcardIds,
    String? imageUrl,
  }) {
    return FlashcardStack(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
