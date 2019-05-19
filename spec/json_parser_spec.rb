# frozen_string_literal: true

require "json"
require_relative "../lib/json_parser"

RSpec.describe JsonParser do
  def parse(input)
    described_class.new(input).run
  end

  table = [
    ["{}", {}],
    ["null", nil],
    ["[]", []],
    ['{"a": "b"}', { "a" => "b" }],
    ['{"a": null}', { "a" => nil }],
    ['{"a": [0]}', { "a" => [0] }],
    ['{"a": [0, 1]}', { "a" => [0, 1] }],
    ['{"a": [0, 1], "b": null}', { "a" => [0, 1], "b" => nil }],
    ['{"a": [0, 1], "b": {"c": "d"}}', { "a" => [0, 1], "b" => { "c" => "d" } }],
    ['{       "a":    "b"   }', { "a" => "b" }],
    ['{"a": 12.1}', { "a" => 12.1 }],
  ]

  table.each do |(input, expected)|
    it "parses #{input}" do
      expect(parse(input)).to eq(expected)
    end
  end

  Dir.glob("fixtures/y_*.json").each do |file|
    input = File.read(file)
    it file do
      expect(parse(input)).to eq(JSON.parse(input))
    end
  end
end
