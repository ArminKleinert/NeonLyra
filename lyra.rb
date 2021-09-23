require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'evaluate.rb'
require_relative 'core.rb'

# Treat the first console argument as a filename,
# read from the file and evaluate the result.
begin
  puts evalstr(IO.read("core1.lyra"))
  ARGV.each do |f|
    evalstr(IO.read(f))
  end
rescue SystemStackError
  $stderr.puts "Internal call stack: #{$lyra_call_stack}"
  raise
rescue
  $stderr.puts "Internal callstack: " + $lyra_call_stack.to_s
  $stderr.puts "Error: " + $!.message
  #$stderr.puts LYRA_ENV.to_s
  raise
end
