class BubbleTranslationService
  PROMPT = <<~PROMPT
    This image shows a single speech bubble or text area cropped from a manga or comic page.

    Extract and translate all visible text to English.

    Respond ONLY in this exact JSON format:
    {
      "raw_text": "original text exactly as written",
      "translated_text": "English translation",
      "notes": "any translator notes or empty string"
    }

    If the bubble contains no readable text:
    { "raw_text": "", "translated_text": "", "notes": "no text found" }

    Return ONLY valid JSON. No markdown, no backticks, no preamble.
  PROMPT

  def initialize(translation_job)
    @job   = translation_job
    @batch = translation_job.translation_batch
  end

  def call
    bubbles = @job.speech_bubbles.ordered
    return 0 if bubbles.empty?

    original_path = download_image_to_tempfile

    bubbles.each { |bubble| translate_bubble(bubble, original_path) }

    bubbles.count
  ensure
    File.delete(original_path) if original_path && File.exist?(original_path)
  end

  private

  def translate_bubble(bubble, original_path)
    crop_path = crop_bubble(bubble, original_path)
    return unless crop_path

    result = call_llm(crop_path)
    bubble.update!(
      raw_text:        result["raw_text"].to_s.strip,
      translated_text: result["translated_text"].to_s.strip
    )
  rescue => e
    Rails.logger.warn "BubbleTranslationService: bubble #{bubble.id} failed — #{e.message}"
    bubble.update!(raw_text: "", translated_text: "[translation failed: #{e.message}]")
  ensure
    File.delete(crop_path) if crop_path && File.exist?(crop_path)
  end

  def crop_bubble(bubble, original_path)
    img = MiniMagick::Image.open(original_path)
    px  = bubble.pixel_bbox(img.width, img.height)
    return nil if px[:w] < 4 || px[:h] < 4

    crop_path = Rails.root.join("tmp", "bubble_crop_#{bubble.id}.png").to_s
    img.crop("#{px[:w]}x#{px[:h]}+#{px[:x]}+#{px[:y]}")
    img.format("png")
    img.write(crop_path)
    crop_path
  end

  def call_llm(crop_path)
    image_bytes   = File.binread(crop_path)
    provider      = @batch.model_provider
    adapter_class = ImageTranslationService::ADAPTER_MAP.fetch(provider) do
      raise ArgumentError, "Unknown provider: #{provider}"
    end
    adapter_class.new(@job).translate_bubble_crop(image_bytes, "image/png", PROMPT)
  rescue JSON::ParserError
    { "raw_text" => "", "translated_text" => "[JSON parse error]", "notes" => "" }
  end

  def download_image_to_tempfile
    ext  = File.extname(@job.image.blob.filename.to_s).downcase
    ext  = ".jpg" if ext.empty?
    path = Rails.root.join("tmp", "btranslate_job#{@job.id}#{ext}").to_s
    File.binwrite(path, @job.image.download)
    path
  end
end
