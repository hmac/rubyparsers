# frozen_string_literal: true

require_relative "../lib/parser"

RSpec.describe Parser do
  let(:parser) { described_class.new("hello") }

  describe "#take" do
    it "consumes n characters" do
      expect(parser.take(1)).to eq("h")
      expect(parser.take(2)).to eq("el")
    end

    it "fails if it cannot consume n characters" do
      expect { parser.take(6) }.to raise_error(described_class::ParseFailure)
      expect(parser.take(1)).to eq("h")
    end
  end

  describe "#string" do
    it "succeeds if the input starts with the string" do
      expect(parser.string("hel")).to eq("hel")
      expect(parser.string("lo")).to eq("lo")
    end

    it "fails if the input does not start with the string" do
      expect { parser.string("no") }.to raise_error(described_class::ParseFailure)
      expect(parser.string("hel")).to eq("hel")
    end
  end

  describe "#take_while" do
    it "consumes characters as long as the predicate holds" do
      expect(parser.take_while(proc { |c| c != "o" })).to eq("hell")
      expect(parser.take_while(proc { |c| c == "o" })).to eq("o")
    end

    it "consumes no characters if the predicate does not hold" do
      expect(parser.take_while(proc { |c| c == "x" })).to eq("")
      expect(parser.take_while(proc { |c| c != "o" })).to eq("hell")
    end
  end

  describe "#sep_by" do
    let(:sep) { proc { parser.string(",") } }
    let(:input) { "a,b,c" }
    let(:parser) { described_class.new(input) }

    it "returns each match of the parser, separated by the separator" do
      expect(parser.sep_by(sep, proc { parser.take(1) })).to eq(%w[a b c])
    end

    context "when the parser only matches once, at the start of the input" do
      let(:input) { "a" }
      it "returns that match" do
        expect(parser.sep_by(sep, proc { parser.take(1) })).to eq(["a"])
      end
    end

    context "when the separator does not match" do
      let(:input) { "a-b-c" }
      it "returns the first match only" do
        expect(parser.sep_by(sep, proc { parser.take(1) })).to eq(["a"])
      end
    end
  end

  describe "#between" do
    let(:open) { proc { parser.string("h") } }
    let(:close) { proc { parser.string("l") } }

    it "parses the open and close on either side of the parser" do
      expect(parser.between(open, close, proc { parser.string("e") })).to eq("e")
    end
  end

  describe "#either" do
    it "succeeds if the first parser succeeds" do
      p1 = proc { parser.string("h") }
      p2 = proc { parser.string("x") }
      expect(parser.either(p1, p2)).to eq("h")
    end

    it "succeeds if the first parser fails but the second succeeds" do
      p1 = proc { parser.string("x") }
      p2 = proc { parser.string("h") }
      expect(parser.either(p1, p2)).to eq("h")
    end

    it "fails if both parsers fail" do
      p1 = proc { parser.string("x") }
      p2 = proc { parser.string("y") }
      expect { parser.either(p1, p2) }.to raise_error(described_class::ParseFailure)

      expect(parser.string("h")).to eq("h")
    end
  end

  describe "#at_least_one" do
    it "fails if the parser matches 0 times" do
      p = proc { parser.string("x") }

      expect { parser.at_least_one(p) }.to raise_error(described_class::ParseFailure)
    end

    it "succeeds if the parser matches once" do
      p = proc { parser.string("h") }

      expect(parser.at_least_one(p)).to eq(["h"])
      expect(parser.take(1)).to eq("e")
    end

    it "succeeds if the parser matches more than once" do
      h = proc { parser.string("h") }
      e = proc { parser.string("e") }
      p = proc { parser.either(h, e) }

      expect(parser.at_least_one(p)).to eq(%w[h e])
      expect(parser.take(1)).to eq("l")
    end
  end
end
