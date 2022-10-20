ls = File.foreach("core.lyra")

=begin
ls.drop(1).each do |l|
  l_prefix = l.start_with?(";#")
  last_block_prefix = arr[-1][-1].start_with?(";#")
  if l_prefix == last_block_prefix # same prefix
    arr[-1] << l
  else
    arr << [l]
  end
end

arr.each_with_index do |b, i|
  if b[0].start_with?(";#")
    sigs  = b.filter{|s|s.include?(" : ") && !s[(s.index(" : ")+3)..-1].empty?}

    type = arr[i+1][0].include?("defmacro") ? "Macro" : "Function"
    sub = sigs[0][3 .. -1]
    sub = sub[0 ... sub.index(" ")]
    sigs[0] = ";## #{type}: #{sub}\n#{sigs[0]}"

    other = b.reject{|s|s.include?(" : ") && !s[(s.index(" : ")+3)..-1].empty?}
    arr[i] = sigs + other
  end
end

IO.write "core2.lyra", arr.map(&:join).join
=end

REG = /;#\s.+:.+->.+/

blocks = []
Block = Struct.new :name, :line, :sig, :pure, :description
ls = ls.each_with_index.map{|l, i| [l, i+1]}
loop do
  ls = ls.drop_while{|l, _| !l.strip.start_with?(";##")}

  if ls.first.nil?
    break
  end

  line = ls.first[1]
  sub = ls.take_while{|l, _| l.start_with?(";#")}.map{|l,_| l.strip}.to_a
  ls = ls.drop(sub.size)

  name = sub[0][3..-1].strip
  sub = sub[1..-1]
  sigs = sub.filter{ |l| l =~ REG }
  description = sub.reject{ |l| l =~ REG }
  pure = !(name.split(" ").last.strip.end_with?("!"))

  blocks << Block.new(name, line, sigs, pure, description)
  puts blocks[-1].to_s
end

def format_block(b)
  sig = b.sig.map{|s| s[3..-1]}
  desc = b.description.map{|d|d[3..-1]}
  res = "#{sig.join("\n")}\n\nPure? #{b.pure ? "Yes" : "No"}\n\n#{desc.join("\n")}".lines.map{|l|"  #{l}"}.join
  res = "### #{b.name.split(" ").join(" `")}` \n```\n" + res + "\n```\n"
  res
end

blocks2 = blocks.partition{|b|b.name.start_with?("Function")}.map{|xs|xs.sort_by(&:name)}.map{|xs| xs.map{|b|format_block(b)}.join}

res = "## Macros\n\n"
res += blocks2[1]
res += "\n"
res += "## Functions\n\n"
res += blocks2[0]

IO.write("core_functions.md", res)
