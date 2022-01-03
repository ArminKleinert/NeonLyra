#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'

# [\s,]*                ignore whitespace and comma
# \\u[0-9]{4}           utf-8 literals
# \\.                   Other char literals
# [()\[\]\{\}]          Special opening and closing brackets.
# "(?:\\.|[^\\"])*"?    String literals
# ;.*                   Ignore rest of line after semicolon
# @                     '@' character
# #\{                   Special symbol '#{'
# #\(                   Special symbol '#('
# '                     Special symbol '
# [^\s\[\]\{\}('"`,;)]* Anything else, excluding spaces, [, ], (, ), {, }, ', ", `, comma and semicolon
LYRA_REGEX = /[\s,]*(\\u[0-9]{4}|\\.|[()\[\]\{\}]|"(?:\\.|[^\\"])*"?|;.*|@|#\{|#\(|[^\s\[\]\{\}('"`,;)]*'{0,1}|')/

# Scan the text using RE, remove empty tokens and remove comments.
def tokenize(s)
  s.scan(LYRA_REGEX).flatten.reject { |w| w.empty? || w.start_with?(";") }
end

# Un-escapes a string and removed the '"' from beginning and end.
def parse_str(token)
  token.gsub(/\\./, { "\\\\" => "\\", "\\n" => "\n", "\\\"" => '"' })[1..-2].freeze
end

def parse_char(token)
  case token
  when /^\\u[0-9]{4}$/
    LyraChar.conv(eval('"'+token+'"').encode('utf-8'))
  when /^\\[A-Za-z0-9+-\/!?$%&()\|\[\]\{\}]$/
    LyraChar.conv token[1]
  when "\\*"
    LyraChar.conv "*"
  when "\\newline"
    LyraChar.conv "\n"
  when "\\space"
    LyraChar.conv " "
  when "\\tab"
    LyraChar.conv "\t"
  when "\\backspace"
    LyraChar.conv 8.chr
  when "\\return"
    LyraChar.conv 13.chr
  when "\\formfeed"
    LyraChar.conv 12.chr
  else
    raise LyraError.new("Invalid char literal: \\#{token}")
  end
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
      root << list(:quote, make_ast(tokens, level+1, "", true))
    when "@"
      root << list(:unbox, make_ast(tokens, level+1, "", true))
    when '#{'
      a = make_ast(tokens, level+1, "}")
      root << (a.is_a?(Array) ? Set[*a] : Set[a])
    when "{"
      a = make_ast(tokens, level+1, "}")
      root << a.each_slice(2).to_h
    when "#("
      root << list(:lambda, list(:"&", 0.chr.to_sym), make_ast(tokens, level, ")"))
    when "("
      root << make_ast(tokens, level + 1, ")")
    when ")"
      raise LyraError.new("Unexpected ')'", :"parse-error") if level == 0 || expected != ")"
      return list(*root)
    when "["
      root << make_ast(tokens, level + 1, "]")
    when "]"
      raise LyraError.new("Unexpected '#{t}'", :"parse-error") if level == 0 || expected != t
      return root.to_a
    when "}"
      raise LyraError.new("Unexpected '#{t}'", :"parse-error") if level == 0 || expected != t
      return root.to_a
    when '"' then raise LyraError.new("Unexpected '\"'", :"parse-error")
    when "#t", "true" then root << true
    when "#f", "false" then root << false
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
    when /^-?[0-9]+\/[0-9]+r$/
      root << t.to_r
    when /^"(?:\\.|[^\\"])*"$/ then root << parse_str(t)
    when ".?"
      raise LyraError.new(".? on empty AST.", :"parse-error") if root.empty?
      root[-1] = list(:unwrap, root[-1])
    when ".!"
      raise LyraError.new(".! on empty AST.", :"parse-error") if root.empty?
      root[-1] = list(:eager, root[-1])
    when /^::.+$/
      root << t.to_sym #TypeName.new(t,-1)
    when /^:.+$/
      root << Keyword.create(t)
    when /^\\.+$/
      root << parse_char(t)
    else
      applications = []
      while t.end_with?(".?") || t.end_with?(".!")
        applications << (t.end_with?(".?") ? :unwrap : :eager)
        t = t[0..-3]
      end
      if t == "Nothing"
        t = nil
      elsif t.empty?
        raise LyraError.new("Empty symbols are not allowed.", :"parse-error")
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
  raise LyraError.new("Expected ')', got EOF", :"parse-error") if level != 0
  list(*root)
end

