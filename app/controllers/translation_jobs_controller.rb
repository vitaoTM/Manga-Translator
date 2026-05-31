class TranslationJobsController < ApplicationController
  def show
    @job = TranslationJob.find(params[:id])
    render json: {
      id: @job.id,
      status: @job.status,
      source_language: @job.source_language,
      translated_text: @job.translated_text,
      error_message: @job.error_message,
      image_url: @job.image.attached? ? url_for(@job.image) : nil
    }
  end
end
