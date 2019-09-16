#!/usr/bin/ruby

count = 441
ARGF.each do |line|
  todo_base = line.chomp
  curr_name = sprintf "todo/%s.todo", todo_base
  new_name = sprintf "todo/%04d_%s.todo", count, todo_base
  count += 1
  puts "mv -v #{curr_name} #{new_name}"
end
