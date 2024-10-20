REG = /;#\s.+:.+->.+/
Block = Struct.new :name, :line, :sigs, :pure, :description

def format_block(b)
  sig = b.sigs.map { |s| s[3..-1] }
  desc = b.description.map { |d| d[3..-1] }
  res = "#{sig.join("\n")}\n\nPure? #{b.pure ? "Yes" : "No"}#{desc.empty? ? "" : "\n\n"}#{desc.join("\n")}".lines.map { |l| "  #{l}" }.join
  "### #{b.name.split(" ").join(" `")}` \n```\n" + res + "\n```\n"
end

def dostuff(filename, target_file)
  ls = File.foreach(filename)

  blocks = []
  ls = ls.map(&:strip).each_with_index.map { |l, i| [l, i + 1] }
  loop do
    ls = ls.drop_while { |l, _| !l.strip.start_with?(";##") }

    if ls.first.nil?
      break
    end

    line = ls.first[1]
    sub = ls.take_while { |l, _| l.start_with?(";#") }.map { |l, _| l.strip }.to_a
    ls = ls.drop(sub.size)

    name = sub[0][3..-1].strip
    sub = sub[1..-1]
    sigs = sub.filter { |l| l =~ REG }
    description = sub.reject { |l| l =~ REG }
    pure = !(name.split(" ").last.strip.end_with?("!"))

    blocks << Block.new(name, line, sigs, pure, description)
    # puts blocks[-1].to_s
  end
  puts "#{filename}: #{blocks.size} entries found."

  blocks2 = blocks.group_by { |b| b.name.split(":", 2)[0].strip }

  res = "# File: #{filename}\n\n"

  if filename == "buildins.lyra"
    res += "Attention! It is not adviced to use any function with the prefix \"buildin\" directly! They may not always act as intended and may be removed at any time in any version.`"
  end

  constants_blocks = blocks2["Constant"]
  unless constants_blocks.nil?
    res += "\n## Constants\n\n"
    res += constants_blocks.sort_by.map { |b| format_block(b) }.join
  end

  macros_blocks = blocks2["Macro"]
  unless macros_blocks.nil?
    res += "\n## Macros\n\n"
    res += macros_blocks.sort_by.map { |b| format_block(b) }.join
  end

  function_blocks = blocks2["Function"]
  unless function_blocks.nil?
    res += "\n## Functions\n\n"
    res += function_blocks.sort_by.map { |b| format_block(b) }.join
  end

  blocks2.delete("Constant")
  blocks2.delete("Macro")
  blocks2.delete("Function")

  blocks2.each_value do |v|
    v.each do |b|
      puts "Unknown type of doc: " + b.name
    end
  end

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
    dostuff("core/" + f, target)
  end
end

