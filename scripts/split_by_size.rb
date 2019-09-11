#!/usr/bin/env ruby

require 'csv'

##
#
# Split objects evenly across groups based on total size of data. For each a
# row the Group column is given a letter, A, B, C, etc.
#
# If there are eight letters A-H, and the total size of all rows is 200 GB,
# then rows with the first 25GB will get group A; the second 25GB, group B; and
# so on.
#
# Sample input:
#
#   repo,Path extension,Priority,Group,Repo Name,size,size_gb,folder,STATUS,Notes
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",13610,0.013,html,,
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",40293,0.038,ljs489,,
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",58830,0.056,ljsmisc4,,
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",66706,0.064,ljs33,,
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",78547,0.075,ljs391,,
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",80375,0.077,ljs115,,
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",102349,0.098,ljs119,,
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",107002,0.102,ljs108,,
#   0001,,2,2_LJS,"University of Pennsylvania Libraries, Lawrence J. Schoenberg Manuscripts",115088,0.11,ljs310,,

headings = %q{key,repo,Path extension,Priority,Group,Repo Name,size,size_gb,folder,STATUS,Notes}.split /,/

total_size = 0

file = ARGV.shift
CSV.foreach file, headers: true do |row|
  total_size += row['size'].to_i
end


GROUPS = %w{ A B C D E F G H }
portion_max = total_size / GROUPS.size

portion = 0
interval = 0
CSV headers: true do |csv|
  csv << headings

  CSV.foreach file, headers: true do |row|
    portion += row['size'].to_i 
    if portion > portion_max
      interval += 1
      portion = 0
    end
    row['Group'] = GROUPS[interval]
    csv << row
  end
end
