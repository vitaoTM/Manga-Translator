class ImageTranslationService
  ADAPTER_MAP = {
    "anthropic" => Translation::AnthropicAdapter,
    "openai"    => Translation::OpenaiAdapter,
    "gemini"    => Translation::GeminiAdapter,
    "ollama"    => Translation::OllamaAdapter
  }.freeze

  def self.call(translation_job)
    provider = translation_job.translation_batch.model_provider
    adapter  = ADAPTER_MAP.fetch(provider) do
      raise ArgumentError, "Unknown provider: #{provider}"
    end
    adapter.new(translation_job).call
  end
end
