require "test_helper"

class Translation::BaseAdapterTest < ActiveSupport::TestCase
  test "parse_json handles clean JSON" do
    adapter = Translation::BaseAdapter.allocate
    result = adapter.send(:parse_json, '{"source_language":"Japanese","has_text":true,"translation":"Hello","notes":""}')
    assert_equal "Japanese", result["source_language"]
    assert_equal "Hello", result["translation"]
  end

  test "parse_json strips backtick fences" do
    adapter = Translation::BaseAdapter.allocate
    raw = "```json\n{\"source_language\":\"Japanese\",\"translation\":\"Hi\"}\n```"
    result = adapter.send(:parse_json, raw)
    assert_equal "Japanese", result["source_language"]
  end

  test "parse_json raises on garbage" do
    adapter = Translation::BaseAdapter.allocate
    assert_raises(JSON::ParserError) { adapter.send(:parse_json, "not json at all") }
  end
end
