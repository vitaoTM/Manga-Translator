require "test_helper"

class TranslationBatchTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    batch = TranslationBatch.new(
      model_provider: "anthropic",
      ai_model: "claude-sonnet-4-20250514"
    )
    assert batch.valid?
  end

  test "invalid with unknown provider" do
    batch = TranslationBatch.new(model_provider: "unknown_provider", ai_model: "x")
    assert_not batch.valid?
    assert_includes batch.errors[:model_provider], "is not included in the list"
  end

  test "status enum defaults to pending" do
    batch = TranslationBatch.create!(model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514")
    assert batch.status_pending?
  end

  test "all defined providers pass validation" do
    TranslationBatch::PROVIDERS.each_key do |provider|
      batch = TranslationBatch.new(model_provider: provider, ai_model: "any")
      batch.valid?
      assert_empty batch.errors[:model_provider], "Provider #{provider} should be valid"
    end
  end

  test "has many translation jobs" do
    batch = translation_batches(:batch_one)
    assert_respond_to batch, :translation_jobs
  end
end
