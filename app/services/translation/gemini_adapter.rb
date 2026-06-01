module Translation
  class GeminiAdapter < BaseAdapter
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

    def call
      model = @job.translation_batch.ai_model
      apikey = ENV.fetch("GEMINI_API_KEY")
      url = "#{BASE_URL}/#{model}:generateContent?key=#{apikey}"

      payload = {
        contents: [ {
          parts: [
            { inline_data: { mime_type: media_type, data: image_base64 } },
            { text: PROMPT }
          ]
        } ],
        generationConfig: { maxOutputTokens: 2048 }
      }

      conn = Faraday.new { |f| f.adapter Faraday.default_adapter }
      res = conn.post(url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = payload.to_json
      end

      raise "Gemini HTTP #{res.status}: #{res.body}" unless res.success?

      body = JSON.parse(res.body)
      text = body.dig("candidates", 0, "content", "parts", 0, "text")
      save_result(parse_json(text))

    rescue JSON::ParserError => e
      save_error("JSON parse error: #{e.message}")
    rescue => e
      save_error("Gemini error: #{e.message}")
    end
  end
end
