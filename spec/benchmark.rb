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
sample2 = File.read("sample2.json")
Benchmark.bm(35) do |x|
  x.report("all files") do
    inputs.each { |input| parse(input) }
  end

  x.report("100KB JSON document") do
    parse(sample2)
  end
end

StackProf.run(mode: :cpu, out: 'prof2.dump', raw: true) do
  parse(sample2)
end
