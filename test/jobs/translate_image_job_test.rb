require "test_helper"

class TranslateImageJobTest < ActiveSupport::TestCase
  setup do
    @batch = TranslationBatch.create!(
      model_provider: "anthropic",
      ai_model:       "claude-sonnet-4-20250514"
    )
    @job = @batch.translation_jobs.build(position: 0)
    @job.save!(validate: false)
    @job.image.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename:     "sample.png",
      content_type: "image/png"
    )
  end

  test "transitions job to processing then delegates to service" do
    ImageTranslationService.stubs(:call).with(@job) do
      @job.update_column(:status, TranslationJob.statuses[:completed])
    end

    TranslateImageJob.new.perform(@job.id)

    @batch.reload
    assert @batch.status_completed?
  end

  test "is idempotent — skips already completed jobs" do
    @job.update_column(:status, TranslationJob.statuses[:completed])
    ImageTranslationService.expects(:call).never

    TranslateImageJob.new.perform(@job.id)
  end

  test "marks batch completed when all jobs finish" do
    job2 = @batch.translation_jobs.build(position: 1)
    job2.save!(validate: false)
    job2.image.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename:     "sample2.png",
      content_type: "image/png"
    )
    job2.update_column(:status, TranslationJob.statuses[:completed])

    ImageTranslationService.stubs(:call).with(@job) do
      @job.update_column(:status, TranslationJob.statuses[:completed])
    end

    TranslateImageJob.new.perform(@job.id)

    @batch.reload
    assert @batch.status_completed?, "Batch should be completed when all jobs are done"
  end

  test "handles missing job gracefully" do
    assert_nothing_raised do
      TranslateImageJob.new.perform(99999999)
    end
  end

  teardown do
    @batch.destroy
  end
end
