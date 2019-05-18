# frozen_string_literal: true

require_relative "../lib/json_parser"
require "benchmark"
require "stackprof"

def parse(input)
  JsonParser.new(input).run
rescue JsonParser::ParseFailure
  nil
end

inputs = Dir.glob("fixtures/y_*.json").map do |file|
  File.read(file)
end
inputs.push(File.read("fixtures/sample4.json"))

sample2 = File.read("fixtures/sample2.json")
Benchmark.bm(35) do |x|
  x.report("all fixtures") do
    inputs.each { |input| parse(input) }
  end

  x.report("100KB JSON document") do
    parse(sample2)
  end
end

# To construct a flamegraph:
# 1. bundle exec ruby spec/benchmark.rb
# 2. bundle exec stackprof --flamegraph profile.dump > flamegraph
# 3. bundle exec stackprof --flamegraph-viewer flamegraph
# 4. open the URL printed by the above command

StackProf.run(mode: :cpu, out: "profile.dump", raw: true) do
  parse(sample2)
end
