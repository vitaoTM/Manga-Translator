module Translation
  class BaseAdapter
    PROMPT = <<~PROMPT
      You are an expert translator specializing in Japanese and other Asian languages.

      Examine this image carefully. If it contains any non-English text:
      1. Identify the source language(s)
      2. Translate ALL visible text to English
      3. Preserve reading order (right-to-left for Japanese manga)
      4. For manga/comics: prefix each bubble with [Panel N - Bubble N]:

      Respond ONLY in this exact JSON format:
      {
        "source_language": "Japanese",
        "has_text": true,
        "translation": "Full English translation here...",
        "notes": "Translator notes, cultural context, or reading order guidance"
      }

      If no translatable text is found:
      { "source_language": null, "has_text": false, "translation": null, "notes": "No text found" }

      Return ONLY valid JSON. No markdown, no backticks, no preamble.
    PROMPT

    def initialize(translation_job)
      @job = translation_job
    end

    def call
      raise NotImplementedError, "#{self.class}#call is not implemented"
    end

    private

    def image_base64
      @image_base64 ||= Base64.strict_encode64(@job.image.download)
    end

    def media_type
      case @job.image.blob.content_type
      when "image/jpeg", "image/jpg" then "image/jpeg"
      when "image/png"               then "image/png"
      when "image/gif"               then "image/gif"
      when "image/webp"              then "image/webp"
      else "image/jpeg"
      end
    end

    def save_result(parsed)
      @job.update!(
        status:          :completed,
        source_language: parsed["source_language"],
        translated_text: parsed["translation"] || "No translatable text found.",
        error_message:   parsed["notes"]
      )
    end

    def save_error(msg)
      @job.update!(status: :failed, error_message: msg)
    end

    def parse_json(raw)
      clean = raw.gsub(/\A```json\s*|\s*```\z/m, "").strip
      JSON.parse(clean)
    end
  end
end
