module Translation
  class OllamaAdapter < BaseAdapter
    def call
      base_url = ENV.fetch("OLLAMA_BASE_URL", "http://localhost:11434")

      client = OpenAI::Client.new(
        access_token: "ollama", uri_base: "#{base_url}/v1/")

      response = client.chat(
        parameters: {
          model: @job.translation_batch.ai_model,
          max_tokens: 2048,
          messages: [ {
            role: "user",
            content: [
              { type: "image_url", image_url: { url: "data:#{media_type};base64,#{image_base64}" } },
              { type: "text", text: PROMPT }
            ]
          } ]
        }
      )

      save_result(parse_json(response.dig("choices", 0, "message", "content")))
    rescue JSON::ParserError => e
      save_error("JSON parse error: #{e.message}")
    rescue => e
      save_error("Ollama error: #{e.message}. Is Ollama running at #{ENV.fetch('OLLAMA_BASE_URL', 'http://localhost:11434')}?")
    end
  end
end
