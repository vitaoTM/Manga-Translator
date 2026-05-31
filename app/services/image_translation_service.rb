class ImageTranslationService
  PROMPT = <<~PROMPT
    You are an expert translator specializing in Japanese and other Asia languages.
    Examine this image carefully. If it contains any non-English text:
    1. Identify the source language(s)
    2. Translate ALL visible text to English
    3. Preserve the reading order (top-to-botton, right-to-left for japanese manga panels)
    4. For manga/comincs: prefix each spexh buble or caption with a label like [Panel 1 - Buble 1]:

    Respond in this exact JSON format:
    {
      "source_language": "Japanese",
      "has_text" true,
      "translation": "Full English translation here...",
      "notes": "Any translator notes, cutural context, or reading order guidance"
    }

    If no translatable text is found, respond:
    {#{' '}
      "source_language": null,
      "has_text": false,
      "translation": null,
      "non-English": "No text found"
    }

    Return ONLY valid JSON. No markdown, no backticks, no preamble.
  PROMPT

  def initialize(translation_job)
    @job = translation_job
  end

  def call
    image_data = load_image_as_base64
    media_type = detect_media_type

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    response = client.messages(
      model: "claude-sonnet-4-20250514",
      max_tokens: 2048,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: media_type,
                data: image_data
              }
            },
            {
              type: "text",
              text: PROMPT
            }
          ]
        }
      ]
    )

    raw = response.content.first.text
    result = JSON.parse(raw)

    @job.update!(
      status: :completed,
      source_language: result["source_language"],
      translated_text: result["translation"] || "No translatable text found",
      error_message: result["notes"]
    )

  rescue JSON::ParserError => e
    @job.update!(status: :failed, error_message: "Invalid JSON from API: {e.message}")
  rescue Anthropic::Error => e
    @job.update!(status: :failed, error_message: "API error: #{e.message}")
  rescue => e
    @job.update!(status: :failed, error_message: "Unexpectd error: #{e.message}")
  end

  private

  def load_image_as_base64
    @job.image.download.then { |data| Base64.strict_encode64(data) }
  end

  def detect_media_type
    content_type = @job.image.blob.content_type
    case content_type
    when "image/jpeg", "image/jpg" then "image/jpeg"
    when "image/png"               then "image/png"
    when "image/gif"               then "image/gif"
    when "image/webp"              then "image/webp"
    else "image/jpeg"
    end
  end
end
