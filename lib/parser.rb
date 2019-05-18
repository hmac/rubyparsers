# frozen_string_literal: true

class Parser
  class ParseFailure < StandardError; end

  def initialize(input)
    @input = input
    @loc = 0
  end

  def optional(parser)
    match = backtrack { parser.call }
  rescue ParseFailure
    match
  end

  # rubocop:disable Lint/HandleExceptions
  def at_least_one(parser)
    first = parser.call
    rest = zero_or_more(parser)
    [first, *rest]
  end

  def zero_or_more(parser)
    matches = []
    begin
      loop do
        matches << backtrack { parser.call }
      end
    rescue ParseFailure
    end
    matches
  end
  # rubocop:enable Lint/HandleExceptions

  def sep_by(separator, parser)
    first = begin
              backtrack { parser.call }
            rescue ParseFailure
              return []
            end

    combined = proc do
      separator.call
      parser.call
    end
    rest = zero_or_more combined
    [first, *rest]
  end

  def either(parser1, parser2)
    backtrack { parser1.call }
  rescue ParseFailure
    parser2.call
  end

  def one_of(parsers)
    parsers.each do |parser|
      begin
        return backtrack { parser.call }
      rescue ParseFailure
        next
      end
    end
    raise ParseFailure, "expected one of: #{parsers}"
  end

  def string(pat)
    if input.start_with?(pat)
      take(pat.length)
    else
      actual = input.byteslice(0, pat.length)
      fail(pat, actual)
    end
  end

  def take(len)
    match = input.byteslice(0, len)
    if match.length < len
      raise ParseFailure, "expected #{len} characters, but saw #{match.length}"
    end

    consume(len)
    match
  end

  def take_while(pred)
    input.chars.take_while(&pred).join.tap { |match| consume(match.length) }
  end

  def between(open, close, inner)
    backtrack do
      open.call
      inner.call.tap { close.call }
    end
  end

  def fail(expected, actual)
    raise ParseFailure, "expected #{expected.inspect}, but saw #{actual.inspect} (#{@loc})"
  end

  # Return the next character of input without consuming it
  def peek
    input.byteslice(0, 1)
  end

  private

  # Parsers operate on a slice of the input
  def input
    @input.byteslice(@loc..-1)
  end

  # Consume num characters of the input
  def consume(num)
    @loc += num
  end

  def backtrack
    loc_before = @loc
    yield
  rescue ParseFailure
    @loc = loc_before
    raise
  end
end
