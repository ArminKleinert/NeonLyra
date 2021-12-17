#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'evaluate.rb'
require_relative 'core.rb'

# Repl stuff
if RUBY_PLATFORM != "java"
  require "reline"
  HISTORY_LOADED = Box.new(false)
  HISTFILE = "#{ENV['HOME']}/.lyra-history"
  HISTORY = []
end


# Read a line using Reline::readline
# If the history file doesn't exist yet, create it.
# Otherwise, load it lazily.
def _readline(prompt)
  if defined?(Reline)
    # Create history file
    if !File.exists?(HISTFILE)
      IO.write(HISTFILE, "\n")
    end
    # Load history file
    if !HISTORY_LOADED.value && File.exist?(HISTFILE)
      HISTORY_LOADED.value = true
      # Load history
      if File.readable?(HISTFILE)
        File.readlines(HISTFILE).each do |l|
          l = l.chomp
          Reline::HISTORY << l
          HISTORY << l
        end
      end
    end

    # Read a single line
    if line = Reline.readline(prompt, false)
      # Add the line only if it is not equal to the last one.
      HISTORY.each_with_index { |e,i| Reline::HISTORY[i] = e }
      if HISTORY.empty? || HISTORY[-1] != line
        HISTORY << line
        Reline::HISTORY << line
        if File.writable?(HISTFILE)
          File.open(HISTFILE, 'a+') {|f| f.write(line+"\n")}
        end
      end
      line
    end
  else
    print(">> ")
    res = gets
    res ? res.rstrip : res
  end
end


LYRA_VERSION = "0_1_2"

if ARGV[0] == "show_expand_macros"
  $show_expand_macros = true
  ARGV.pop
end
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

  if src_files.empty?
    puts "Welcome to Lyra #{LYRA_VERSION}. \nPress ctrl+D to quit."
    
    loop do
      begin
        s = _readline(">> ") # Read
        break unless s # Quit if the line is empty
        puts elem_to_s(eval_str(s)) # Write the result
      rescue LyraError
        $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
        $stderr.puts "Error: " + $!.message
      rescue Interrupt
        # Ignore
      end
    end
    puts "Bye!"
  end
rescue SystemStackError
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
  raise
rescue
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
  $stderr.puts "Error: " + $!.message
  raise
end
