module Translation
  class AnthropicAdapter < BaseAdapter
    def call
      client = Anthropic::Client.new

      response = client.messages.create(
        model: @job.translation_batch.ai_model,
        max_tokens: 2048,
        messages: [ {
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: media_type, data: image_base64 } },
            { type: "text", text: PROMPT }
          ]
        } ]
      )

      save_result(parse_json(response.content.first.text))

    rescue JSON::ParserError => e
      save_error("JSON parse error: #{e.message}")
    rescue Anthropic::Error => e
      save_error("Anthropic API error: #{e.message}")
    rescue => e
      save_error("Unexpected error: #{e.message}")
    end
  end
end
