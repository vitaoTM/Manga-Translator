require "test_helper"

class TranslateImageJobTest < ActiveSupport::TestCase
  setup do
    @batch = TranslationBatch.create!(model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514")
    @job = @batch.translation_jobs.build(position: 0)
    @job.image.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename:     "sample.png",
      content_type: "image/png"
    )
    @job.save!
  end

  test "runs full pipeline when bubbles are detected" do
    ImageTranslationService.stubs(:call).with(@job)
    BubbleDetectionService.any_instance.stubs(:call).returns(3)
    BubbleTranslationService.any_instance.stubs(:call).returns(3)
    ImageCompositorService.any_instance.stubs(:call).returns("/tmp/fake.jpg")

    TranslateImageJob.new.perform(@job.id)

    @job.reload
    assert @job.status_completed?
  end

  test "skips compositor when no bubbles detected" do
    ImageTranslationService.stubs(:call).with(@job)
    BubbleDetectionService.any_instance.stubs(:call).returns(0)
    BubbleTranslationService.any_instance.expects(:call).never
    ImageCompositorService.any_instance.expects(:call).never

    TranslateImageJob.new.perform(@job.id)

    @job.reload
    assert @job.status_completed?
  end

  test "is idempotent — skips already completed jobs" do
    @job.update!(status: :completed)
    ImageTranslationService.expects(:call).never

    TranslateImageJob.new.perform(@job.id)
  end

  test "sets failed status and re-raises on service error" do
    ImageTranslationService.stubs(:call).raises(RuntimeError, "API timeout")

    assert_raises(RuntimeError) do
      TranslateImageJob.new.perform(@job.id)
    end

    @job.reload
    assert @job.status_failed?
    assert_match "API timeout", @job.error_message
  end

  test "handles missing job gracefully" do
    assert_nothing_raised { TranslateImageJob.new.perform(99999999) }
  end

  test "marks batch completed when all jobs finish" do
    job2 = @batch.translation_jobs.build(position: 1)
    job2.image.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename:     "sample2.png",
      content_type: "image/png"
    )
    job2.save!
    job2.update!(status: :completed)

    ImageTranslationService.stubs(:call)
    BubbleDetectionService.any_instance.stubs(:call).returns(0)

    TranslateImageJob.new.perform(@job.id)

    @batch.reload
    assert @batch.status_completed?
  end

  teardown { @batch.destroy }
end
