require "test_helper"

class TranslationBatchesControllerTest < ActionDispatch::IntegrationTest
  test "GET /index returns 200" do
    get root_path
    assert_response :success
  end

  test "GET /new returns 200" do
    get new_translation_batch_url
    assert_response :success
  end

  test "GET /show returns 200" do
    batch = TranslationBatch.create!(
      model_provider: "anthropic",
      ai_model: "claude-sonnet-4-20250514"
    )

    get translation_batch_url(batch)
    assert_response :success
    batch.destroy
  end

  test "GET /show responds to JSON format" do
    batch = TranslationBatch.create!(
      model_provider: "anthropic",
      ai_model: "claude-sonnet-4-20250514"
    )

    get translation_batch_url(batch), headers: { "Accept" => "application/json" }
    assert_response :success
    data = JSON.parse(response.body)

    assert_equal batch.id, data["id"]
    assert_equal "pending", data["status"]
    assert_equal false, data["completed"]
    batch.destroy
  end

  test "POST /create with no images redirects with alert" do
   post translation_batches_url, params: { model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514" }
   assert_redirected_to new_translation_batch_url
   assert_equal "Please select at least one image.", flash[:alert]
  end

  test "POST /create with images creates batch and jobs" do
    TranslateImageJob.expects(:perform_later).once
    image_file = fixture_file_upload("sample.png", "image/png")

    assert_difference [ "TranslationBatch.count", "TranslationJob.count" ], 1 do
      post translation_batches_url, params: {
      images: [ image_file ],
      model_provider: "anthropic",
      ai_model: "claude-sonnet-4-20250514",
      title: "Test Upload"
      }
    end

    assert_redirected_to translation_batch_url(TranslationBatch.last)
    assert_equal "anthropic", TranslationBatch.last.model_provider
  end
end
