require "test_helper"

class BubbleTranslationServiceTest < ActiveSupport::TestCase
  setup do
    @batch = TranslationBatch.create!(model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514")
    @job = @batch.translation_jobs.build(position: 0)
    @job.image.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename:     "sample.png",
      content_type: "image/png"
    )
    @job.save!
    @bubble = @job.speech_bubbles.create!(
      bbox_x: 0.0, bbox_y: 0.0, bbox_w: 1.0, bbox_h: 1.0,
      confidence: 0.9, position: 0
    )
  end

  test "translates all bubbles for a job" do
    BubbleTranslationService.any_instance.stubs(:crop_bubble).returns("/tmp/fake_crop.png")
    BubbleTranslationService.any_instance.stubs(:call_llm).returns(
      { "raw_text" => "テスト", "translated_text" => "Test text", "notes" => "" }
    )

    count = BubbleTranslationService.new(@job).call

    @bubble.reload
    assert_equal 1,           count
    assert_equal "テスト",    @bubble.raw_text
    assert_equal "Test text", @bubble.translated_text
  end

  test "handles LLM failure gracefully without raising" do
    BubbleTranslationService.any_instance.stubs(:crop_bubble).returns("/tmp/fake_crop.png")
    BubbleTranslationService.any_instance.stubs(:call_llm).raises(RuntimeError, "API down")

    assert_nothing_raised { BubbleTranslationService.new(@job).call }

    @bubble.reload
    assert_match "translation failed", @bubble.translated_text
  end

  test "skips zero-size bubble crops" do
    @job.speech_bubbles.create!(
      bbox_x: 0.0, bbox_y: 0.0, bbox_w: 0.001, bbox_h: 0.001,
      confidence: 0.9, position: 1
    )
    BubbleTranslationService.any_instance.expects(:call_llm).never

    BubbleTranslationService.new(@job).call
  end

  test "returns 0 when no bubbles exist" do
    @job.speech_bubbles.destroy_all
    assert_equal 0, BubbleTranslationService.new(@job).call
  end

  teardown { @batch.destroy }
end
