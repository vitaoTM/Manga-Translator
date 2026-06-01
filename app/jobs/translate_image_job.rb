class TranslateImageJob < ApplicationJob
  queue_as :default

  def perform(translation_job_id)
    job = TranslationJob.find(translation_job_id)
    return if job.status_completed?

    job.update!(status: :processing)
    ImageTranslationService.call(job)

    batch = job.translation_batch
    if batch.translation_jobs.reload.all? { |j| j.status_completed? || j.status_failed? }
      batch.update!(status: :completed)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "TranslateImageJob: TranslationJob ##{translation_job_id} not found"
  end
end
