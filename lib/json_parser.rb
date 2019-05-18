# frozen_string_literal: true

require_relative "./parser"

class JsonParser < Parser
  def run
    json_value
  end

  def json_value
    skip_spaces
    one_of [
      method(:object),
      method(:array),
      method(:quoted_string),
      method(:boolean),
      method(:null),
      method(:number),
    ]
  end

  def object
    inner = proc do
      skip_spaces
      kvs = sep_by method(:comma), method(:key_value_pair)
      skip_spaces
      Hash[kvs]
    end
    between proc { string "{" },
            proc { string "}" },
            inner
  end

  def null
    string "null"
    nil
  end

  def array
    res = between proc { string "["; skip_spaces },
                  proc { skip_spaces; string "]" },
                  proc { sep_by method(:comma), method(:json_value) }
    skip_spaces
    res
  end

  def boolean
    bool = either proc { string "true" }, proc { string "false" }
    bool == "true"
  end

  # rubocop:disable Metrics/AbcSize
  def number
    result = integer
    decimals = optional(proc { string "."; integer })
    exponent = optional(proc { either(proc { string "e" }, proc { string "E" }); integer })

    result = result.to_f if decimals || exponent
    result += (decimals.to_f / (10**decimals.to_s.length)) if decimals
    result *= 10**exponent.to_f if exponent
    result
  end
  # rubocop:enable Metrics/AbcSize

  INTEGERS = (0..9).map(&:to_s)
  # rubocop:disable Style/SignalException
  def integer
    int = proc do
      char = take 1
      fail("one of #{INTEGERS}", char) unless INTEGERS.include?(char)

      char
    end

    sign = optional method(:sign)
    numstr = at_least_one int
    n = numstr.join("").to_i
    sign == "-" ? 0 - n : n
  end
  # rubocop:enable Style/SignalException

  def sign
    either proc { string "-" },
           proc { string "+" }
  end

  def key_value_pair
    key = quoted_string
    string ":"
    skip_spaces
    value = json_value
    [key, value]
  end

  def quoted_string
    between proc { string "\"" },
            proc { string "\"" },
            proc { take_while(proc { |c| c != "\"" }) }
  end

  def skip_spaces
    take_while(proc { |c| [" ", "\n"].include?(c) })
  end

  def comma
    string ","
    skip_spaces
  end
end
