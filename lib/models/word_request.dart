class WordRequest {
  final String targetLanguageCode;
  final String nativeLanguageCode;

  const WordRequest({
    required this.targetLanguageCode,
    required this.nativeLanguageCode,
  });

  Map<String, dynamic> toJson() => {
    'targetLanguageCode': targetLanguageCode,
    'nativeLanguageCode': nativeLanguageCode,
  };
}