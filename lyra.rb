#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'evaluate.rb'
require_relative 'core.rb'

LYRA_VERSION = "0_1_1"

if ARGV.include? "-args"
  src_files, lyra_args = ARGV.slice_after{|e| e == "-args"}.to_a
  Env.global_env.set!(:"*ARGS*", lyra_args ? lyra_args.map(&:freeze).freeze : list())
  src_files.pop
else
  src_files = ARGV
end

# Treat the first console argument as a filename,
# read from the file and evaluate the result.
begin
  puts elem_to_s(eval_str(IO.read("core.lyra")))
  src_files.each do |f|
    puts elem_to_s(eval_str(IO.read(f)))
  end

  #print ">> "
  #s = gets
  #while s
  #  puts elem_to_s(eval_str(s))
  #  print ">> "
  #  s = gets
  #end
  puts "Bye!"
rescue SystemStackError
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
  raise
rescue
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
  $stderr.puts "Error: " + $!.message
  raise
end
