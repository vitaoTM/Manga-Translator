require "test_helper"

class BubbleDetectionServiceTest < ActiveSupport::TestCase
  setup do
    @batch = TranslationBatch.create!(model_provider: "anthropic", ai_model: "claude-sonnet-4-20250514")
    @job = @batch.translation_jobs.build(position: 0)
    @job.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )

    @job.save!
  end

  test "iou returns 0 for non-identical boxes" do
    svc = BubbleDetectionService.allocate
    box = { x: 0.1, y: 0.1, w: 0.3, h: 0.3 }
    assert_in_delta 1.0, svc.send(:iou, box, box), 0.001
  end

  test "greedy_nms removes overlaping boxes" do
    svc = BubbleDetectionService.allocate
    boxes = [
      { x: 0.1, y: 0.1, w: 0.3, h: 0.3, confidence: 0.95 },
      { x: 0.11, y: 0.11, w: 0.3, h: 0.3, confidence: 0.80 },
      { x: 0.7, y: 0.7, w: 0.2, h: 0.2, confidence: 0.75 }
    ]

    result = svc.send(:greedy_nms, boxes, 0.45)
    assert_equal 2, result.size
    assert_equal 0.95, result.first[:confidence]
  end

  test "pixel_bbox math is correct end-to-end" do
    bubble = SpeechBubble.new(
      translation_job: @job,
      bbox_x: 0.25, bbox_y: 0.10,
      bbox_w: 0.50, bbox_h: 0.20,
      confidence: 0.9, position: 0
    )

    px = bubble.pixel_bbox(800, 600)
    assert_equal 200, px[:x]
    assert_equal 60,  px[:y]
    assert_equal 400, px[:w]
    assert_equal 120, px[:h]
  end

  test "call persist SpeechBubble records and updates job status" do
    fake_detections = [
      [ 0.2, 0.15, 0.25, 0.18, 0.91 ],
      [ 0.7, 0.60, 0.20, 0.15, 0.78 ]
    ]

    fake_output = { "output0" => [ [
      fake_detections.map { |d| d[0] },
      fake_detections.map { |d| d[1] },
      fake_detections.map { |d| d[2] },
      fake_detections.map { |d| d[3] },
      fake_detections.map { |d| d[4] }
    ] ] }

    fake_model = mock
    fake_model.stubs(:predict).returns(fake_output)
    BubbleDetectionService.stubs(:model).returns(fake_model)

    assert_difference "SpeechBubble.count", 2 do
      BubbleDetectionService.new(@job).call
    end

    @job.reload
    assert @job.bubble_detection_status_bubbles_detected?
    assert_equal 2, @job.bubble_count
  end

  test "sets status to bubbles_failed on error" do
    BubbleDetectionService.stubs(:model).raises(RuntimeError, "model crash")

    assert_raises(RuntimeError) do
      BubbleDetectionService.new(@job).call
    end

    @job.reload
    assert @job.bubble_detection_status_bubbles_failed?
  end

  teardown { @batch.destroy }
end
