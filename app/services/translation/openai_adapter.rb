module Translation
  class OpenaiAdapter < BaseAdapter
    def call
      client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))

      response = client.chat(
        parameters: {
          model:      @job.translation_batch.model_name,
          max_tokens: 2048,
          messages: [ {
            role: "user",
            content: [
              { type: "image_url", image_url: { url: "data:#{media_type};base64,#{image_base64}" } },
              { type: "text",      text: PROMPT }
            ]
          } ]
        }
      )

      save_result(parse_json(response.dig("choices", 0, "message", "content")))
    rescue JSON::ParserError => e
      save_error("JSON parse error: #{e.message}")
    rescue => e
      save_error("OpenAI error: #{e.message}")
    end
  end
end
