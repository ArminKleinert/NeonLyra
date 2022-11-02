
REG = /;#\s.+:.+->.+/
Block = Struct.new :name, :line, :sig, :pure, :description

def format_block(b)
  sig = b.sig.map{|s| s[3..-1]}
  desc = b.description.map{|d|d[3..-1]}
  res = "#{sig.join("\n")}\n\nPure? #{b.pure ? "Yes" : "No"}#{desc.empty? ? "" : "\n\n"}#{desc.join("\n")}".lines.map{|l|"  #{l}"}.join
  res = "### #{b.name.split(" ").join(" `")}` \n```\n" + res + "\n```\n"
  res
end

def dostuff(filename, target_file)
  ls = File.foreach(filename)

  blocks = []
  ls = ls.map(&:strip).each_with_index.map{|l, i| [l, i+1]}
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
    #puts blocks[-1].to_s
  end

  blocks2 = blocks.partition{|b|b.name.start_with?("Function")}.map{|xs|xs.sort_by(&:name)}.map{|xs| xs.map{|b|format_block(b)}.join}

  res = "# File: #{filename}\n\n"

  if filename == "buildins.lyra"
    res +=  "Attention! It is not adviced to use any function with the prefix \"buildin\" directly! They may not always act as intended and may be removed at any time in any version.`"
  end

  res += "\n\n## Macros\n\n"
  res += blocks2[1]
  res += "\n"
  res += "## Functions\n\n"
  res += blocks2[0]
  
  target_file.puts res
end

out_file = "core_functions.md"
IO.write out_file, "" # Clear file

src_files = ["core.lyra", "buildins.lyra", "set.lyra", "string.lyra", "vector.lyra"]

open(out_file, "a") do |target|
  src_files.each do |f|
    dostuff(f, target)
  end
end

out_file = "stdlib_functions.md"
IO.write out_file, "" # Clear file

src_files = ["aliases.lyra", "clj.lyra", "infix.lyra", "queue.lyra", "random.lyra", "sort.lyra"]

open(out_file, "a") do |target|
  src_files.each do |f|
    dostuff("core/"+f, target)
  end
end

