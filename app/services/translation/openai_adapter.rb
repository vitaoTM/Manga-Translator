module Translation
  class OpenaiAdapter < BaseAdapter
    def call
      client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))

      response = client.chat(
        parameters: {
          model:                 @job.translation_batch.ai_model,
          max_completion_tokens: 2048,
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
      body = e.respond_to?(:response) ? e.response&.dig(:body).to_s : ""
      save_error("OpenAI error: #{e.message} #{body}".strip)
    end

    def translate_bubble_crop(image_bytes, content_type, prompt)
      client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))

      response = client.chat(
        parameters: {
          model:                 @job.translation_batch.ai_model,
          max_completion_tokens: 512,
          messages: [ {
            role:    "user",
            content: [
              { type: "image_url", image_url: { url:
"data:#{content_type};base64,#{Base64.strict_encode64(image_bytes)}" } },
              { type: "text",      text: prompt }
            ]
          } ]
        }
      )

      parse_json(response.dig("choices", 0, "message", "content"))
    end
  end
end
