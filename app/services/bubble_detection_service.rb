class BubbleDetectionService
  MODEL_INPUT_SIZE = 1024
  CONFIDENCE_THRESHOLD = 0.35
  NMS_IOU_THRESHOLD = 0.45

  def initialize(translation_job)
    @job = translation_job
  end

  def call
    @job.update!(bubble_detection_status: :bubbles_detecting)

    model    = self.class.model
    img_path = download_image_to_tempfile
    orig_img = MiniMagick::Image.open(img_path)
    orig_w   = orig_img.width
    orig_h   = orig_img.height

    input_tensor, pad_info = preprocess(img_path, orig_w, orig_h)

    raw_output = model.predict({ "images" => input_tensor })
    detections = raw_output.values.first[0].transpose

    boxes = postprocess(detections, orig_w, orig_h, pad_info)

    boxes.each_with_index do |box, idx|
      @job.speech_bubbles.create!(
        bbox_x:     box[:x],
        bbox_y:     box[:y],
        bbox_w:     box[:w],
        bbox_h:     box[:h],
        confidence: box[:confidence],
        position:   idx
      )
    end

    @job.update!(
      bubble_detection_status: :bubbles_detected,
      bubble_count:            boxes.size
    )

    Rails.logger.info "BubbleDetectionService: #{boxes.size} bubbles detected for job #{@job.id}"
    boxes.size
  rescue => e
    @job.update!(bubble_detection_status: :bubbles_failed)
    raise e
  ensure
    File.delete(img_path) if img_path && File.exist?(img_path)
  end

  def self.model
    @model ||= OnnxRuntime::Model.new(ML_MODELS[:bubble_detector])
  end

  private

  def download_image_to_tempfile
    ext  = File.extname(@job.image.blob.filename.to_s).downcase
    ext  = ".jpg" if ext.empty?

    path = Rails.root.join("tmp", "bubble_detect_job#{@job.id}#{ext}").to_s
    File.binwrite(path, @job.image.download)
    path
  end

  def preprocess(img_path, orig_w, orig_h)
    size  = MODEL_INPUT_SIZE
    scale = [ size.to_f / orig_w, size.to_f / orig_h ].min
    new_w = (orig_w * scale).round
    new_h = (orig_h * scale).round
    pad_x = ((size - new_w) / 2.0).round
    pad_y = ((size - new_h) / 2.0).round

    resized = MiniMagick::Image.open(img_path)
    resized.combine_options do |c|
      c.resize "#{new_w}x#{new_h}"
      c.background "rgb(114,114,114)"
      c.gravity "center"
      c.extent "#{size}x#{size}"
    end

    pixels = resized.get_pixels  # [H, W, 3]
    h = pixels.length
    w = pixels[0].length

    r_plane = Array.new(h) { |y| Array.new(w) { |x| pixels[y][x][0] / 255.0 } }
    g_plane = Array.new(h) { |y| Array.new(w) { |x| pixels[y][x][1] / 255.0 } }
    b_plane = Array.new(h) { |y| Array.new(w) { |x| pixels[y][x][2] / 255.0 } }

    tensor   = [ [ r_plane, g_plane, b_plane ] ]  # [1, 3, H, W]
    pad_info = { pad_top: pad_y, pad_left: pad_x, scale: scale }
    [ tensor, pad_info ]
  end

  def postprocess(detections, orig_w, orig_h, pad_info)
    size  = MODEL_INPUT_SIZE
    scale = pad_info[:scale]
    pad_x = pad_info[:pad_left]
    pad_y = pad_info[:pad_top]

    candidates = detections.select { |d| d[4] >= CONFIDENCE_THRESHOLD }
    return [] if candidates.empty?

    boxes = candidates.map do |d|
      cx_1024 = d[0] * size
      cy_1024 = d[1] * size
      w_1024  = d[2] * size
      h_1024  = d[3] * size

      cx_orig = (cx_1024 - pad_x) / scale
      cy_orig = (cy_1024 - pad_y) / scale
      w_orig  = w_1024 / scale
      h_orig  = h_1024 / scale

      x = cx_orig - w_orig / 2.0
      y = cy_orig - h_orig / 2.0
      x = x.clamp(0, orig_w)
      y = y.clamp(0, orig_h)
      w = w_orig.clamp(0, orig_w - x)
      h = h_orig.clamp(0, orig_h - y)

      {
        x:          (x / orig_w).round(6),
        y:          (y / orig_h).round(6),
        w:          (w / orig_w).round(6),
        h:          (h / orig_h).round(6),
        confidence: d[4].round(4)
      }
    end

    boxes.sort_by { |b| -b[:confidence] }
          .then { |sorted| greedy_nms(sorted, NMS_IOU_THRESHOLD) }
  end

  def greedy_nms(boxes, iou_threshold)
    kept      = []
    remaining = boxes.dup
    while remaining.any?
      best = remaining.shift
      kept << best
      remaining.reject! { |b| iou(best, b) > iou_threshold }
    end
    kept
  end

  def iou(a, b)
    ax2 = a[:x] + a[:w];  ay2 = a[:y] + a[:h]
    bx2 = b[:x] + b[:w];  by2 = b[:y] + b[:h]

    ix1 = [ a[:x], b[:x] ].max;  iy1 = [ a[:y], b[:y] ].max
    ix2 = [ ax2,   bx2  ].min;  iy2 = [ ay2,   by2  ].min

    iw = [ ix2 - ix1, 0 ].max
    ih = [ iy2 - iy1, 0 ].max
    intersection = iw * ih

    union = a[:w] * a[:h] + b[:w] * b[:h] - intersection
    union > 0 ? intersection / union : 0.0
  end
end
