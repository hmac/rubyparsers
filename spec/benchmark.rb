# frozen_string_literal: true

require_relative "../lib/json_parser"
require "benchmark"
require "stackprof"

def parse(input)
  JsonParser.new(input).run
rescue JsonParser::ParseFailure
end

inputs = Dir.glob("JSONTestSuite/test_parsing/y_*.json").map do |file|
  File.read(file)
end
inputs.push(File.read("sample4.json"))

n = 50
Benchmark.bm(35) do |x|
  x.report("all files") do
    inputs.each { |input| parse(input) }
  end
end
