class FlashcardStack {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<String> flashcardIds; // References to flashcards in this stack
  final String? imageUrl;

  FlashcardStack({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.flashcardIds,
    this.imageUrl,
  });

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'flashcardIds': flashcardIds,
    'imageUrl': imageUrl,
  };

  factory FlashcardStack.fromJson(Map<String, dynamic> json) => FlashcardStack(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    createdAt: DateTime.parse(json['createdAt']),
    flashcardIds: List<String>.from(json['flashcardIds']),
    imageUrl: json['imageUrl'],
  );
}