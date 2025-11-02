enum LlmType {
  CHATGPT('ChatGPT'),
  PERPLEXITY('Perplexity'),
  GROK('Grok'),
  DEEPSEEK('DeepSeek'),
  LOCAL('Local LLM');

  final String displayName;
  const LlmType(this.displayName);
}
