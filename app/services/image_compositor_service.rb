require "open3"

class ImageCompositorService
  MIN_FONT_SIZE = 8
  MAX_FONT_SIZE = 48
  TEXT_PADDING  = 1

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
    cx = px[:x] + px[:w] / 2
    cy = px[:y] + px[:h] / 2

    img.combine_options do |c|
      c.fill "white"
      c.draw "ellipse #{cx},#{cy} #{(px[:w] / 2 * 0.94).round},#{(px[:h] / 2 * 0.94).round} 0,360"
    end

    text_w = [ (px[:w] * 0.70).round, 30 ].max
    text_h = [ (px[:h] * 0.70).round, 30 ].max
    text_x = [ cx - text_w / 2, 0 ].max
    text_y = [ cy - text_h / 2, 0 ].max

    text_img_path = Rails.root.join("tmp", "text_#{bubble.id}.png").to_s
    caption_path  = Rails.root.join("tmp", "caption_#{bubble.id}.txt").to_s
    File.write(caption_path, bubble.translated_text.to_s)

    Open3.capture2(
      "magick",
      "-size",       "#{text_w}x#{text_h}",
      "-background", "white",
      "-fill",       "black",
      "-font",       ML_MODELS[:noto_font],
      "-gravity",    "Center",
      "caption:@#{caption_path}",
      text_img_path
    )

    return unless File.exist?(text_img_path)

    Open3.capture2(
      "magick", "composite",
      "-geometry", "+#{text_x}+#{text_y}",
      text_img_path,
      img.path,
      img.path
    )
  ensure
    File.delete(text_img_path) if text_img_path && File.exist?(text_img_path)
    File.delete(caption_path)  if caption_path  && File.exist?(caption_path)
  end

  def measure_text(text, font_size, avail_w = nil)
    caption_path = Rails.root.join("tmp", "measure_#{SecureRandom.hex(6)}.txt").to_s
    File.write(caption_path, text.to_s)
    args = [ "magick", "-font", ML_MODELS[:noto_font], "-pointsize", font_size.to_s, "-format", "%wx%h" ]
    args += avail_w ? [ "-size", "#{avail_w}x", "caption:@#{caption_path}" ] : [ "label:@#{caption_path}" ]
    args << "info:"
    out, = Open3.capture2(*args)
    parts = out.strip.split("x").map(&:to_i)
    [ parts[0].to_i, parts[1].to_i ]
  rescue
    [ 999, 999 ]
  ensure
    File.delete(caption_path) if caption_path && File.exist?(caption_path)
  end

  # def measure_text(text, font_size, avail_w = nil)
  #   args = [ "magick", "-font", ML_MODELS[:noto_font], "-pointsize", font_size.to_s, "-format", "%wx%h" ]
  #   args += avail_w ? [ "-size", "#{avail_w}x", "caption:#{text}" ] : [ "label:#{text}" ]
  #   args << "info:"
  #   out, = Open3.capture2(*args)
  #   parts = out.strip.split("x").map(&:to_i)
  #   [ parts[0].to_i, parts[1].to_i ]
  # rescue
  #   [ 999, 999 ]
  # end

  def download_image_to_tempfile
    ext  = File.extname(@job.image.blob.filename.to_s).downcase
    ext  = ".jpg" if ext.empty?
    path = Rails.root.join("tmp", "compositor_job#{@job.id}#{ext}").to_s
    File.binwrite(path, @job.image.download)
    path
  end
end
