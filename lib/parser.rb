# frozen_string_literal: true

class Parser
  class ParseFailure < StandardError; end

  def initialize(input)
    @input = input
    @loc = 0
  end

  def optional(parser)
    backtrack { parser.call }
  rescue ParseFailure
    nil
  end

  def at_least_one(parser)
    first = parser.call
    rest = zero_or_more(parser)
    [first, *rest]
  end

  def zero_or_more(parser)
    matches = []
    loop { matches << backtrack { parser.call } }
    matches
  rescue ParseFailure
    matches
  end

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
    backtrack do
      s = take(pat.length)
      fail(s, pat) unless s == pat

      s
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

  # This was originally defined as follows
  #   def take_while(pred)
  #     input.chars.take_while(&pred).join.tap { |match| consume(match.length) }
  #   end
  # but the following definition, while less readable, is about 30x faster
  def take_while(pred)
    take_matching = proc do
      c = take 1
      pred.call(c) ? c : (raise ParseFailure)
    end

    str = +""
    loop { str << backtrack { take_matching.call } }
    str
  rescue ParseFailure
    str
  end

  def between(open, close, inner)
    backtrack do
      open.call
      inner.call.tap { close.call }
    end
  end

  def fail(expected, actual)
    raise ParseFailure, "expected #{expected.inspect} but saw #{actual.inspect} (#{@loc})"
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
