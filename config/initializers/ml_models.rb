ML_MODELS = {
  bubble_detector: Rails.root.join("lib/ml_models/bubble_detector.onnx").to_s,
  noto_font:       Rails.root.join("lib/fonts/NotoSans-Regular.ttf").to_s
}.freeze
