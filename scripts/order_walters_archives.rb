#!/usr/bin/env ruby

require 'csv'

input_csv = File.expand_path '../../data/Glacier_sizes.csv', __FILE__

data_blocks = {}
GROUPS = %i{ a b c d }

CSV.foreach(input_csv, headers: true).with_index do |row,index|
  # binding.pry
  next if row['size_in_gb'].to_f < 100
  next if row['size_in_gb'].to_f > 199
  # break if row['size_in_gb'].to_f > 100
  if index < 41
    (data_blocks[:first_set] ||= []) << row.to_hash
  else
    g_index = index % GROUPS.size
    # g_index = ((index - 39)/100) % GROUPS.size
    group = GROUPS[g_index]
    (data_blocks[group] ||= []) << row.to_hash
  end
end
headers = %w{ size size_in_gb directory group }

# binding.pry

position = 0
CSV headers: true do |csv|
  csv << headers
  data_blocks[:first_set] and data_blocks[:first_set].each do |row|
    row['group']  = :first_set
    csv << row
  end
  (0..).each do |i|
    rows = GROUPS.map { |group|
      hash = data_blocks[group][i]
      if hash.nil?
        nil
      else
        hash.merge('group' => group)
      end
    }.compact
    break if rows.empty?
    rows.each { |row| csv << row }
  end
end

