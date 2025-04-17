class WordResponse {
  final List<WordItem> words;

  const WordResponse({required this.words});

  factory WordResponse.fromJson(Map<String, dynamic> json) {
    return WordResponse(
      words: (json['words'] as List)
          .map((item) => WordItem.fromJson(item))
          .toList(),
    );
  }
}

class WordItem {
  final String word;
  final String translation;
  final String imageUrl;

  const WordItem({
    required this.word,
    required this.translation,
    required this.imageUrl,
  });

  factory WordItem.fromJson(Map<String, dynamic> json) {
    return WordItem(
      word: json['word'] as String,
      translation: json['translation'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}