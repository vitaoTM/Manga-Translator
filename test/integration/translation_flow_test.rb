require "test_helper"

class TranslationFlowTest < ActionDispatch::IntegrationTest
  test "full upload → job creation → completion flow" do
    get new_translation_batch_url
    assert_response :success

    TranslateImageJob.expects(:perform_later).once

    image = fixture_file_upload("sample.png", "image/png")
    post translation_batches_url, params: {
      title:          "Integration test batch",
      model_provider: "anthropic",
      model_name:     "claude-sonnet-4-20250514",
      images:         [image]
    }

    batch = TranslationBatch.last
    assert_redirected_to translation_batch_url(batch)
    follow_redirect!
    assert_response :success

    assert_equal "Integration test batch", batch.title
    assert_equal "anthropic",             batch.model_provider
    assert_equal 1,                       batch.translation_jobs.count
    assert                                batch.translation_jobs.first.image.attached?

    job = batch.translation_jobs.first
    job.update_column(:status, TranslationJob.statuses[:completed])
    job.update_columns(source_language: "Japanese", translated_text: "Hello from the test", error_message: "Panel 1")
    batch.update_column(:status, TranslationBatch.statuses[:completed])

    get translation_batch_url(batch)
    assert_response :success
    assert_match "Hello from the test", response.body
    assert_match "Japanese",            response.body
    assert_match "COMPLETED",           response.body
  end

  test "JSON endpoint returns correct completed state" do
    batch = TranslationBatch.create!(
      model_provider: "openai",
      ai_model:       "gpt-4o",
      status:         :completed
    )

    get translation_batch_url(batch), headers: { "Accept" => "application/json" }
    data = JSON.parse(response.body)

    assert_equal "completed", data["status"]
    assert_equal true,        data["completed"]

    batch.destroy
  end
end
