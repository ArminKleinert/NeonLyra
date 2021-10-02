require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'evaluate.rb'
require_relative 'core.rb'

LYRA_VERSION = "0_0_4"

# Treat the first console argument as a filename,
# read from the file and evaluate the result.
begin
  puts elem_to_s(eval_str(IO.read("core1.lyra")))
  ARGV.each do |f|
    elem_to_s(eval_str(IO.read(f)))
  end
rescue SystemStackError
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK}"
  raise
rescue
  $stderr.puts "Internal callstack: #{LYRA_CALL_STACK}"
  $stderr.puts "Error: " + $!.message
  raise
end
