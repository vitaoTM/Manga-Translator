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
end
