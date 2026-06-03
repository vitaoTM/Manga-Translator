require "test_helper"

class ImageCompositorServiceTest < ActiveSupport::TestCase
  setup do
    @batch = TranslationBatch.create!(model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514")
    @job = @batch.translation_jobs.build(position: 0)
    @job.image.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename:     "sample.png",
      content_type: "image/png"
    )

    @job.save!
    @job.speech_bubbles.create!(
      bbox_x: 0.1, bbox_y: 0.1, bbox_w: 0.8, bbox_h: 0.3,
      confidence: 0.9, position: 0,
      raw_text: "テスト", translated_text: "This is a test translation."
    )
  end

  test "attaches rendered_image to the job" do
    ImageCompositorService.new(@job).call
    @job.reload
    assert @job.rendered_image.attached?
  end

  test "rendered image is a valid JPEG" do
    ImageCompositorService.new(@job).call
    @job.reload
    assert_equal "image/jpeg", @job.rendered_image.blob.content_type
  end

  test "returns nil and does not raise when no translated bubbles exist" do
    @job.speech_bubbles.destroy_all
    result = nil
    assert_nothing_raised { result = ImageCompositorService.new(@job).call }
    assert_nil result
    assert_not @job.rendered_image.attached?
  end

  test "skips bubbles with blank translated_text" do
    @job.speech_bubbles.first.update!(translated_text: "")
    result = ImageCompositorService.new(@job).call
    assert_nil result
    assert_not @job.reload.rendered_image.attached?
  end

  teardown { @batch.destroy }
end
