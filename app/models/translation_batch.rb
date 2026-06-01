class TranslationBatch < ApplicationRecord
  has_many :translation_jobs, -> { order(:position) }, dependent: :destroy

  enum :status, {
    pending:    0,
    processing: 1,
    completed:  2,
    failed:     3
  }, prefix: true

  PROVIDERS = {
    "anthropic" => {
      label: "Claude (Anthropic)",
      models: [
        [ "Claude Sonnet 4",  "claude-sonnet-4-20250514" ],
        [ "Claude Opus 4",    "claude-opus-4-20250514" ],
        [ "Claude Haiku 3.5", "claude-haiku-3-5-20241022" ]
      ]
    },
    "openai" => {
      label: "OpenAI",
      models: [
        [ "GPT-4o",       "gpt-4o" ],
        [ "GPT-4o mini",  "gpt-4o-mini" ],
        [ "GPT-4 Turbo",  "gpt-4-turbo" ]
      ]
    },
    "gemini" => {
      label: "Google Gemini",
      models: [
        [ "Gemini 2.0 Flash", "gemini-2.0-flash" ],
        [ "Gemini 1.5 Pro",   "gemini-1.5-pro" ]
      ]
    },
    "ollama" => {
      label: "Ollama (Local)",
      models: [
        [ "LLaVA",            "llava" ],
        [ "LLaMA 3.2 Vision", "llama3.2-vision" ],
        [ "Gemma3 (vision)",  "gemma3" ],
        [ "Custom model…",    "custom" ]
      ]
    }
  }.freeze

  validates :model_provider, inclusion: { in: PROVIDERS.keys }
end
