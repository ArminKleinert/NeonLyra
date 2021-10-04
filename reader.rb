#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'

# [\s,]* Whitespace
# '\(\) Matches the empty list '() (also called nil)
# [()] Matches (, )
# "(?:\\.|[^\\"])*"? Matches 0 or 1 string
# ;.* Matches comment and rest or line
# '?[^\s\[\]{}('"`,;)]* Everything else with an optional ' at the beginning.
LYRA_REGEX = /[\s,]*([()\[\]]|"(?:\\.|[^\\"])*"?|;.*|@|'|[^\s\[\]{}('"`,;)]*)/

# Scan the text using RE, remove empty tokens and remove comments.
def tokenize(s)
  s.scan(LYRA_REGEX).flatten.reject { |w| w.empty? || w.start_with?(";") }
end

# Un-escapes a string and removed the '"' from beginning and end.
def parse_str(token)
  token.gsub(/\\./, { "\\\\" => "\\", "\\n" => "\n", "\\\"" => '"' })[1..-2].freeze
end

# Builds the abstract syntax tree and converts all expressions into their
# types.
# For example, if a token is recognized as a bool, it is parsed into
# a bool, a string becomes a string, etc.
# If an `(` is found, a cons is opened. It is closed when a `)` is 
# encountered.
def make_ast(tokens, level = 0, expected = "", stop_after_1 = false)
  root = []
  while (t = tokens.shift) != nil
    case t
    when "'"
      root << list(:quote, make_ast(tokens, level, "", true))
    when "@"
      root << list(:unbox, make_ast(tokens, level, "", true))
    when "("
      root << make_ast(tokens, level + 1, ")")
    when ")"
      raise "Unexpected ')'" if level == 0 || expected != ")"
      return list(*root)
    when "["
      root << make_ast(tokens, level + 1, "]")
    when "]"
      raise "Unexpected ']'" if level == 0 || expected != "]"
      return root.to_a
    when '"' then raise "Unexpected '\"'"
    when "#t" then root << true
    when "#f" then root << false
    when /^(-?0b[0-1]+|-?0x[0-9a-fA-F]+|-?[0-9]+)$/
      mult = 1
      base = 1
      if t[0] == "-"
        mult = -1
        t = t[1..-1]
      end

      case t[0..1]
      when "0x"
        t = t[2..-1]
        base *= 16
      when "0b"
        t = t[2..-1]
        base *= 2
      else
        base *= 10
      end

      n = t.to_i(base) * mult
      root << n
    when /^-?[0-9]+\.[0-9]+$/
      root << t.to_f
    when /^"(?:\\.|[^\\"])*"$/ then root << parse_str(t)
    else
      applications = []
      while t.end_with?(".?") || t.end_with?(".!")
        applications << (t.end_with?(".?") ? :unwrap : :eager)
        t = t[0..-3]
      end
      if t == "Nothing"
        t = nil
      elsif t.empty?
        raise "Empty symbols are not allowed."
      else
        t = t.to_sym
      end
      applications.reverse_each do |a|
        t = list(a, t)
      end

      root << t
    end
    return root[0] if stop_after_1
  end
  raise "Expected ')', got EOF" if level != 0
  list(*root)
end

