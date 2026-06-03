require "test_helper"

class BubblePipelineTest < ActionDispatch::IntegrationTest
  test "full bubble pipeline: upload → show page renders correctly" do
    TranslateImageJob.expects(:perform_later).once

    image = fixture_file_upload("sample.png", "image/png")
    post translation_batches_url, params: {
      title:          "Pipeline integration test",
      model_provider: "anthropic",
      model_name:     "claude-sonnet-4-20250514",
      images:         [ image ]
    }

    batch = TranslationBatch.last
    assert_redirected_to translation_batch_url(batch)
    follow_redirect!
    assert_response :success

    job = batch.translation_jobs.first
    job.update!(
      status:          :completed,
      source_language: "Japanese",
      translated_text: "Full image translation",
      bubble_count:    2
    )
    batch.update!(status: :completed)

    2.times do |i|
      job.speech_bubbles.create!(
        bbox_x: 0.1 + i * 0.4, bbox_y: 0.1,
        bbox_w: 0.3, bbox_h: 0.2,
        confidence: 0.9 - i * 0.05,
        position: i,
        raw_text:        "テスト#{i}",
        translated_text: "Test bubble #{i + 1}"
      )
    end

    job.rendered_image.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename:     "rendered.jpg",
      content_type: "image/jpeg"
    )

    get translation_batch_url(batch)
    assert_response :success
    assert_match "Full image translation",  response.body
    assert_match "Test bubble 1",           response.body
    assert_match "Test bubble 2",           response.body
    assert_match /2 bubbles\s+detected/,    response.body
    assert_match "Speech bubble breakdown", response.body
    assert_match "Translated",              response.body

    batch.destroy
  end

  test "show page renders gracefully when no bubbles detected" do
    batch = TranslationBatch.create!(
      model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514",
      status: :completed
    )
    job = batch.translation_jobs.build(
      position: 0, status: :completed,
      source_language: "Japanese",
      translated_text: "No bubbles here",
      bubble_count: 0
    )
    job.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "sample.png", content_type: "image/png"
    )
    job.save!

    get translation_batch_url(batch)
    assert_response :success
    assert_match "No bubbles here", response.body
    assert_no_match "Speech bubble breakdown", response.body

    batch.destroy
  end
end
