require "zip"

class TranslationBatchesController < ApplicationController
  def index
    @batches = TranslationBatch.order(created_at: :desc).includes(:translation_jobs)
  end

  def new
    @batch = TranslationBatch.new
  end

  def create
    images = params[:images]
    return redirect_to new_translation_batch_path, alert: "Please select at least one image." if images.blank?

    provider   = params[:model_provider].presence || "anthropic"
    model_name = params[:model_name].presence

    if provider == "ollama" && model_name == "custom"
      model_name = params[:custom_model_name].presence || "llava"
    end

    model_name ||= TranslationBatch::PROVIDERS.dig(provider, :models, 0, 1)

    @batch = TranslationBatch.create!(
      title:          params[:title].presence || "Batch #{Time.current.strftime('%b %d %H:%M')}",
      status:         :pending,
      model_provider: provider,
      ai_model:       model_name
    )

    images.each_with_index do |image_file, idx|
      job = @batch.translation_jobs.build(position: idx)
      job.image.attach(image_file)
      job.save!
      TranslateImageJob.perform_later(job.id)
    end

    @batch.update!(status: :processing)
    redirect_to @batch, notice: "#{images.size} image(s) queued for translation with #{model_name}."
  end

  def show
    @batch = TranslationBatch
               .includes(translation_jobs: { image_attachment: :blob })
               .find(params[:id])
    @jobs = @batch.translation_jobs

    respond_to do |format|
      format.html
      format.json do
        render json: {
          id:        @batch.id,
          status:    @batch.status,
          completed: @batch.status_completed? || @batch.status_failed?,
          progress:  @batch.translation_jobs.where(status: [ :completed, :failed ]).count
        }
      end
    end
  end

  def download_all
    @batch = TranslationBatch
                .includes(translation_jobs: { rendered_image_attachment: :blob })
                .find(params[:id])

    jobs_with_images = @batch.translation_jobs.select { |j| j.rendered_image.attached? }

    if jobs_with_images.empty?
      redirect_to @batch, alert: "No translated images available yet."
      return
    end

    zip_data = Zip::OutputStream.write_buffer do |zip|
      jobs_with_images.each do |job|
        zip.put_next_entry("page#{job.position + 1}_translated.jpg")
        zip.write(job.rendered_image.download)
      end
    end

    send_data zip_data.string,
      filename: "#{@batch.title.parameterize}-translated.zip",
      type:     "application/zip",
      disposition: "attachment"
  end
end
