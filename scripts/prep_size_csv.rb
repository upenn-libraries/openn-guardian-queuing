#!/usr/bin/env ruby

require 'csv'

# Take a simple input csv of size and folder name and add a column for
# size in GB.
#
# Input sample:
#
#   size,repo,folder
#   2613,20,html
#   9124724,20,PC1
#   120244971,20,PC10
#   34810998,20,PC11
#   24952886,20,PC2
#   42493355,20,PC3
#   35242327,20,PC4
#   11386505,20,PC5
#   53194255,20,PC6
#   35374885,20,PC7I
#   37007915,20,PC7II
#   42054972,20,PC8
#   22203175,20,PC9
#
# Output sample:
#
#   size,size_gb,repo,folder
#   2613,0.002,0020,html
#   9124724,8.702,0020,PC1
#   120244971,114.675,0020,PC10
#   34810998,33.198,0020,PC11
#   24952886,23.797,0020,PC2
#   42493355,40.525,0020,PC3
#   35242327,33.61,0020,PC4
#   11386505,10.859,0020,PC5
#   53194255,50.73,0020,PC6

file=ARGV.shift

abort "Can't find file: #{file}" unless File.exist? file

headers = %w{ size size_gb repo folder }
CSV headers: true do |csv|
  csv << headers
  CSV.foreach file, headers: true do |row|
    new_row            = row.to_h
    size_gb            = row['size'].to_f / (1024**2)
    new_row['size_gb'] = size_gb.round 3
    new_row['repo']    = sprintf "%04d", new_row['repo']
    
    csv << new_row
  end
end
