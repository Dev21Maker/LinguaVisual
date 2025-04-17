class Language {
  final String code;
  final String name;
  final String nativeName;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

// Predefined list of supported languages
final List<Language> supportedLanguages = [
  Language(code: 'en', name: 'English', nativeName: 'English'),
  Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
  Language(code: 'fr', name: 'French', nativeName: 'Français'),
  Language(code: 'de', name: 'German', nativeName: 'Deutsch'),
  Language(code: 'it', name: 'Italian', nativeName: 'Italiano'),
  Language(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
  Language(code: 'ru', name: 'Russian', nativeName: 'Русский'),
  Language(code: 'ja', name: 'Japanese', nativeName: '日本語'),
  Language(code: 'zh', name: 'Chinese', nativeName: '中文'),
  Language(code: 'ko', name: 'Korean', nativeName: '한국어'),
];