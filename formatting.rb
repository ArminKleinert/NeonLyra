ls = File.foreach("core.lyra").lazy
arr = [[ls.first]]

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

