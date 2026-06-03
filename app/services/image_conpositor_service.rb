class ImageCompositorService
  MIN_FONT_SIZE = 8
  MAX_FONT_SIZE = 32
  TEXT_PADDING  = 4

  def initialize(translation_job)
    @job = translation_job
  end

  def call
    bubbles = @job.speech_bubbles.translated.ordered
    return nil if bubbles.empty?

    img_path = download_image_to_tempfile
    img      = MiniMagick::Image.open(img_path)
    img_w    = img.width
    img_h    = img.height

    bubbles.each do |bubble|
      next if bubble.translated_text.blank?
      draw_translation(img, bubble, img_w, img_h)
    end

    output_path = Rails.root.join("tmp", "rendered_job#{@job.id}.jpg").to_s
    img.format("jpeg")
    img.quality(92)
    img.write(output_path)

    @job.rendered_image.attach(
      io:           File.open(output_path),
      filename:     "translated_job#{@job.id}.jpg",
      content_type: "image/jpeg"
    )

    output_path
  ensure
    File.delete(img_path)    if img_path    && File.exist?(img_path)
    File.delete(output_path) if output_path && File.exist?(output_path)
  end

  private

  def draw_translation(img, bubble, img_w, img_h)
    px = bubble.pixel_bbox(img_w, img_h)

    img.combine_options do |c|
      c.fill "white"
      c.draw "rectangle #{px[:x]},#{px[:y]} #{px[:x] + px[:w]},#{px[:y] + px[:h]}"
    end

    text      = bubble.translated_text
    font_size = fit_font_size(text, px[:w], px[:h])
    return if font_size < MIN_FONT_SIZE

    text_x = px[:x] + TEXT_PADDING
    text_y = px[:y] + font_size + TEXT_PADDING

    img.combine_options do |c|
      c.font      ML_MODELS[:noto_font]
      c.fill      "black"
      c.pointsize font_size
      c.size      "#{px[:w] - TEXT_PADDING * 2}x#{px[:h] - TEXT_PADDING * 2}"
      c.annotate  "+#{text_x}+#{text_y}", text
    end
  end

  def fit_font_size(text, max_w, max_h)
    low  = MIN_FONT_SIZE
    high = MAX_FONT_SIZE
    best = low

    while low <= high
      mid = (low + high) / 2
      w, h = measure_text(text, mid)
      if w <= max_w - TEXT_PADDING * 2 && h <= max_h - TEXT_PADDING * 2
        best = mid
        low  = mid + 1
      else
        high = mid - 1
      end
    end

    best
  end

  def measure_text(text, font_size)
    result = MiniMagick::Tool::Convert.new do |c|
      c.font      ML_MODELS[:noto_font]
      c.pointsize font_size
      c.format    "%wx%h"
      c << "label:#{text.gsub(/"/, '\\"')}"
      c << "info:"
    end
    parts = result.split("x").map(&:to_i)
    [ parts[0].to_i, parts[1].to_i ]

  rescue
    [ 999, 999 ]
  end

  def download_image_to_tempfile
    ext  = File.extname(@job.image.blob.filename.to_s).downcase
    ext  = ".jpg" if ext.empty?
    path = Rails.root.join("tmp", "compositor_job#{@job.id}#{ext}").to_s
    File.binwrite(path, @job.image.download)
    path
  end
end
