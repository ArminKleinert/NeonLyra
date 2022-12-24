#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'evaluate.rb'
require_relative 'core.rb'

# Repl stuff
if RUBY_PLATFORM != "java"
  begin
    require "reline"
    HISTORY_LOADED = Box.new(false)
    HISTORY_FILE = "#{ENV['HOME']}/.lyra-history"
    HISTORY = []
  rescue LoadError => e
    # reline could not be loaded => ignore
  end
end

# Read a line using Reline::readline
# If the history file doesn't exist yet, create it.
# Otherwise, load it lazily.
def _readline(prompt)
  if defined?(Reline)
    # Create history file
    unless File.exists?(HISTORY_FILE)
      IO.write(HISTORY_FILE, "\n")
    end
    # Load history file
    if !HISTORY_LOADED.value && File.exist?(HISTORY_FILE)
      HISTORY_LOADED.value = true
      # Load history
      if File.readable?(HISTORY_FILE)
        File.readlines(HISTORY_FILE).each do |l|
          l = l.chomp
          Reline::HISTORY << l
          HISTORY << l
        end
      end
    end

    # Read a single line
    if (line = Reline.readline(prompt, false))
      # Add the line only if it is not equal to the last one.
      HISTORY.each_with_index { |e, i| Reline::HISTORY[i] = e }
      if HISTORY.empty? || HISTORY[-1] != line
        HISTORY << line
        Reline::HISTORY << line
        if File.writable?(HISTORY_FILE)
          File.open(HISTORY_FILE, 'a+') { |f| f.write(line + "\n") }
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

LYRA_VERSION = "0_2.0"

if ARGV[0] == "--show_expand_macros"
  $show_expand_macros = true
  ARGV.shift
end

if ARGV.include? "-args"
  src_files, lyra_args = ARGV.slice_after { |e| e == "-args" }.to_a
  Env.global_env.set!(:"*ARGS*", lyra_args ? lyra_args.map(&:freeze).to_cons_list.freeze : EmptyList.instance)
  src_files.shift
else
  src_files = ARGV
  Env.global_env.set!(:"*ARGS*", EmptyList.instance)
end

Env.global_env.set!(:"*lyra-version*", LYRA_VERSION)

# Treat the first console argument as a filename,
# read from the file and evaluate the result.
begin
  puts elem_to_pretty(eval_str(IO.read("core.lyra")))
  src_files.each do |f|
    obj = eval_str(IO.read(f))
    if obj.is_a?(LyraModule)
      obj = list(obj.name, obj.abstract_name)
    end
    puts elem_to_pretty(obj)
  end

  if src_files.empty?
    puts "Welcome to Lyra #{LYRA_VERSION}."
    puts "Press ctrl+D to quit." if defined?(Reline)

    loop do
      begin
        s = _readline(">> ") # Read
        break unless s # Quit if the line is empty
        puts elem_to_pretty(eval_str(s)) # Write the result
      rescue LyraError => e
        $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
        $stderr.puts "Error: " + e.message
      rescue Interrupt
        # Ignore
      end
    end
    puts "Bye!"
  end
rescue SystemStackError
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
  raise
rescue LyraError => e
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
  $stderr.puts "Error: " + e.message
  raise
rescue
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK.map { |x| elem_to_s(x) }}"
  raise
end
