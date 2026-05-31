class TranslationBatchesController < ApplicationController
  def index
    @batches = TranslationBatches.order(created_at: :desc).includes(:translation_jobs)
  end

  def new
    @batch = TranslationBatch.new
  end

  def create
    images = params[:images]

    redirect_to new_translation_batch_path, alert: "Please select at least one image." if images.blank?

    @batch = TranslationBatch.create!(
      title: params[:title].presence || "Batch #{Time.current.strftime('%b %d %H %M')}",
      status: :pending
    )

    images.each_with_index do |image_file, idx|
      job = @batch.translation_jobs.create!(position: idx)
      job.image.attach(image_file)
      TranslateImageJob.perform_latter(job.id)
    end

    @batch.update!(status: :processing)
    redirect_to @batch, notice: "#{images.size} image(s) queued for translation."
  end

  def show
    @batch = TranslationBatch.includes(translation_jobs: { image_attachment: :blob }).find(params[:id])
  end
end
