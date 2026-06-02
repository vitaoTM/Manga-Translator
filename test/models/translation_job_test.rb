require "test_helper"

class TranslationJobTest < ActiveSupport::TestCase
  test "belongs to translation batch" do
    job = translation_jobs(:job_one)
    assert_not_nil job.translation_batch
  end

  test "status enum defaults to pending" do
    job = translation_jobs(:job_one)
    assert job.status_pending?
  end

  test "status transitions work" do
    job = translation_jobs(:job_one)
    job.update_column(:status, TranslationJob.statuses[:processing])
    assert job.status_processing?

    job.update_column(:status, TranslationJob.statuses[:completed])
    assert job.status_completed?
  end

  test "has many speech bubbles" do
    job = translation_jobs(:job_one)
    assert_respond_to job, :speech_bubbles
  end

  test "has one attached rendered_image" do
    job = translation_jobs(:job_one)
    assert_respond_to job, :rendered_image
  end

  test "bubble_detection_status enum defaults to bubbles_pending" do
    batch = TranslationBatch.create!(model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514")
    job = batch.translation_jobs.build(position: 0)
    job.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )
    job.save!
    assert job.bubble_detection_status_bubbles_pending?
    batch.destroy
  end
end
