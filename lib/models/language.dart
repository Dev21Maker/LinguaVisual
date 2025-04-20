class Language {
  final String code;
  final String name;
  final String nativeName;
  final String emoji;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.emoji,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'native_name': nativeName,
      'emoji': emoji,
    };
  }

  static Language fromCode(String code) {
    return supportedLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => supportedLanguages.first,
    );
  }

  /// Creates a Language instance from a JSON map.
  static Language fromMap(Map<String, dynamic> map) {
    return Language(
      code: map['code'] as String,
      name: map['name'] as String,
      nativeName: map['native_name'] as String,
      emoji: map['emoji'] as String,
    );
  }
}

// Predefined list of supported languages
final List<Language> supportedLanguages = [
  Language(code: 'en', name: 'English', nativeName: 'English', emoji: '🇺🇸'),
  Language(code: 'es', name: 'Spanish', nativeName: 'Español', emoji: '🇪🇸'),
  Language(code: 'fr', name: 'French', nativeName: 'Français', emoji: '🇫🇷'),
  Language(code: 'de', name: 'German', nativeName: 'Deutsch', emoji: '🇩🇪'),
  Language(code: 'it', name: 'Italian', nativeName: 'Italiano', emoji: '🇮🇹'),
  Language(code: 'pt', name: 'Portuguese', nativeName: 'Português', emoji: '🇵🇹'),
  Language(code: 'ru', name: 'Russian', nativeName: 'Русский', emoji: '🇷🇺'),
  Language(code: 'ja', name: 'Japanese', nativeName: '日本語', emoji: '🇯🇵'),
  Language(code: 'zh', name: 'Chinese', nativeName: '中文', emoji: '🇨🇳'),
  Language(code: 'ko', name: 'Korean', nativeName: '한국어', emoji: '🇰🇷'),
];