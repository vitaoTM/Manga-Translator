require "test_helper"

class SpeechBubbleTest < ActiveSupport::TestCase
  setup do
    @batch = TranslationBatch.create!(model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514")
    @job = @batch.translation_jobs.build(position: 0)
    @job.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )
    @job.save!
  end

  test "valid with required bbox fields" do
    bubble = SpeechBubble.new(
      translation_job: @job,
      bbox_x: 0.1, bbox_y: 0.2, bbox_w: 0.3, bbox_h: 0.15,
      confidence: 0.92, position: 0
    )

    assert bubble.valid?
  end

  test "invalid without bbox fields" do
    bubble = SpeechBubble.new(translation_job: @job, position: 0)
    assert_not bubble.valid?
    assert_includes bubble.errors[:bbox_x], "can't be blank"
  end

  test "pixel_bbox scales correctly" do
    bubble = SpeechBubble.new(
      translation_job: @job,
      bbox_x: 0.1, bbox_y: 0.2, bbox_w: 0.5, bbox_h: 0.25,
      confidence: 0.9, position: 0
    )

    px = bubble.pixel_bbox(1000, 800)
    assert_equal 100, px[:x]
    assert_equal 160, px[:y]
    assert_equal 500, px[:w]
    assert_equal 200, px[:h]
  end

  test "scopes filter correctly" do
    @job.speech_bubbles.create!(
      bbox_x: 0.1, bbox_y: 0.1, bbox_w: 0.1, bbox_h: 0.1,
      confidence: 0.9, position: 0,
      raw_text: "日本語", translated_text: "Japanese"
    )
    @job.speech_bubbles.create!(
      bbox_x: 0.5, bbox_y: 0.1, bbox_w: 0.1, bbox_h: 0.1,
      confidence: 0.8, position: 1
    )

    assert_equal 2, @job.speech_bubbles.ordered.count
    assert_equal 1, @job.speech_bubbles.with_text.count
    assert_equal 1, @job.speech_bubbles.translated.count
  end

  teardown { @batch.destroy }
end
