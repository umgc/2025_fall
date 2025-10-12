enum LlmType {
  CHATGPT('ChatGPT'),
  PERPLEXITY('Perplexity'),
  GROK('Grok'),
  DEEPSEEK('DeepSeek');

  final String displayName;
  const LlmType(this.displayName);
}
