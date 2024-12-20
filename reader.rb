#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'
require_relative 'evaluate.rb'

# [\s,]*                ignore whitespace and comma
# \\u\d{4}              utf-8 literals
# \\p\(                 Partial function shortcut
# \\.                   Other char literals
# [()\[\]\{\}]          Special opening and closing brackets.
# "(?:\\.|[^\\"])*"?    String literals
# ;.*                   Ignore rest of line after semicolon
# ~@                    unquote-splicing shortcut
# @                     unbox shortcut
# #\{                   Special symbol '#{'
# `                     quasiquote shortcut
# #\(                   Hash-function shortcut
# [^\s\[\]{}('"`,;)]*'? Other symbols and numbers, allowing an optional "'" at the end. This excludes spaces, [, ], (, ), {, }, ', ", `, comma and semicolon
LYRA_REGEX = /[\s,]*(\\u\d{4}|\\p\(|\\.|[()\[\]{}]|"(?:\\.|[^\\"])*"?|;.*|~@|~|@|#\{|`|#\(|[^\s\[\]{}('"`,;)]*'?)/

# Scan the text using RE, remove empty tokens and remove comments.
def tokenize(s)
  s.scan(LYRA_REGEX).flatten.reject { |w| w.empty? || w.start_with?(";") }
end

# Un-escapes a string and removed the '"' from beginning and end.
def parse_str(token)
  token.gsub(/\\./, { "\\\\" => "\\", "\\n" => "\n", "\\\"" => '"' })[1..-2].freeze
end

def parse_char(token)
  c = case token
      when /^\\u\d{4}$/ # Unicode
        LyraChar.conv(eval('"' + token + '"').encode('utf-8'))
      when /^\\[A-Za-z\d+-\/!?$%&()|\[\]{}]$/ # Normal string
        # The type checker complains that token[1] could be nil, which it can't.
        # Even an explicit `raise if token.size < 2` or `raise if token[1].nil?` does nothing.
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
        nil
      end
  if c.nil?
    raise LyraError.new("Invalid char literal: \\#{token}")
  end
  c
end

def prefixed_ast(sym, tokens, level)
  list(sym, make_ast(tokens, level + 1, "", true))
end

def raise_if_unexpected(expected, t, level)
  raise LyraError.new("Unexpected '#{t}'", :"parse-error") if level == 0 || expected != t
end

def read_number(t)
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

  t.to_i(base) * mult
end

# Usually returns a symbol, except for the following cases:
# - The token is "Nothing" -> returns nil
# - The token ends with ".?" -> returns a list with the symbol "unwrap" as it's car (a function call)
# - The token ends with ".!" -> As ".?", but the function is "eager"
# The input can not be ".?" or ".!". Those are handled elsewhere.
def read_symbol(t)
  applications = []
  while t.end_with?(".?") || t.end_with?(".!")
    applications << (t.end_with?(".?") ? :unwrap : :eager)
    t = t[0..-3]
    raise LyraError.new("Internal parser error.", :"parse-error") unless t.is_a? String
  end
  if t == "Nothing"
    res = nil
  elsif t.empty?
    raise LyraError.new("Empty symbols are not allowed.", :"parse-error")
  else
    res = t.to_sym
  end
  applications.reverse_each do |elem|
    res = list(elem, t)
  end
  res
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
      root << prefixed_ast(:quote, tokens, level)
    when "`"
      root << prefixed_ast(:quasiquote, tokens, level)
    when "~"
      root << prefixed_ast(:unquote, tokens, level)
    when "~@"
      root << prefixed_ast(:"unquote-splicing", tokens, level)
    when "@"
      root << prefixed_ast(:unbox, tokens, level)
    when '#{'
      a = make_ast(tokens, level + 1, "}")
      root << (a.is_a?(Array) ? Set[*a] : Set[a])
    when "{"
      a = make_ast(tokens, level + 1, "}")
      root << a.each_slice(2).to_h
    when "#("
      root << list(:lambda, list(:"&", 0.chr.to_sym), make_ast(tokens, level + 1, ")"))
    when "("
      root << make_ast(tokens, level + 1, ")")
    when "\\p("
      temp = make_ast(tokens, level + 1, ")")
      raise LyraError.new("Internal parser error.", :"parse-error") unless temp.is_a?(ConsList)
      root << cons(:partial, temp)
    when ")"
      raise_if_unexpected(expected, t, level)
      return list(*root)
    when "["
      root << make_ast(tokens, level + 1, "]")
    when "]"
      raise_if_unexpected(expected, t, level)
      return root.to_a
    when "}"
      raise_if_unexpected(expected, t, level)
      return root.to_a
    when '"' then raise LyraError.new("Unexpected '\"'", :"parse-error")
    when "#t", "true" then root << true
    when "#f", "false" then root << false
    when /^(-?0b[0-1]+|-?0x[\da-fA-F]+|-?\d+)$/
      root << read_number(t)
    when /^-?\d+\.\d+$/
      root << t.to_f
    when /^-?\d+\/\d+r$/
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
      root << Keyword.create(t[1..-1])
    when /^\\.+$/
      c = parse_char t
      root << c
    else
      root << read_symbol(t)
    end
    return root[0] if stop_after_1
  end
  raise LyraError.new("Expected ')', got EOF", :"parse-error") if level != 0
  list(*root)
end
