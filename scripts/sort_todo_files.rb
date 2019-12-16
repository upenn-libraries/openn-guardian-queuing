#!/usr/bin/env ruby

require 'csv'
require 'fileutils'

################################################################################
# Input:
#
#
#   Key,repo,Path extension,Priority,Group,Repo Name,size,size_gb,folder,STATUS,Notes
#   0014_html,0014,,1,LARGE,Private Collection A,20,0,html,,
#   0014_GalenSyriacPalimpsest,0014,,1,LARGE,Private Collection A,"372,303,892",355.057,GalenSyriacPalimpsest,,
#   0014_ArchimedesPalimpsest,0014,,1,LARGE,Private Collection A,"733,734,829",699.744,ArchimedesPalimpsest,,
#   0020_html,0020,Data/OtherCollections,1,A,The Walters Art Museum,"2,613",0.002,html,,
#   0020_PC1,0020,Data/OtherCollections,1,A,The Walters Art Museum,"9,124,724",8.702,PC1,,
#   0020_PC10,0020,Data/OtherCollections,1,LARGE,The Walters Art Museum,"120,244,971",114.675,PC10,,
#   0020_PC11,0020,Data/OtherCollections,1,A,The Walters Art Museum,"34,810,998",33.198,PC11,,
#   0020_PC2,0020,Data/OtherCollections,1,A,The Walters Art Museum,"24,952,886",23.797,PC2,,
#   0020_PC3,0020,Data/OtherCollections,1,A,The Walters Art Museum,"42,493,355",40.525,PC3,,
#
#################################################################################
def usage
  puts "#{__FILE__} CSV_FILE INPUT_DIR"
end # def usage

unless ARGV.size > 1
  puts "ERROR: Wrong number of arguments"
  usage
  exit 1
end

csv_file  = ARGV.shift
input_dir = ARGV.shift

unless File.exist? csv_file
  puts "ERROR: Cannot find CSV_FILE: '#{csv_file}'"
  usage
  exit 1
end

unless File.directory? input_dir
  puts "ERROR: INPUT_DIR is not a valid directory: '#{input_dir}'"
  usage
  exit 1
end

COUNTS = Hash.new { |hash, group| hash[group] = 0 }


CSV.foreach csv_file, headers: true do |row|
  key           = row['Key']
  todo_expected = File.join input_dir, "#{key}.todo"
  group         = row['Group']
  count         = COUNTS[group] += 1

  out_file      = sprintf "%s%05d_%s", group, count, File.basename(todo_expected)
  out_path      = File.expand_path "../../tmp/todo/#{out_file}", __FILE__
  
  # puts sprintf("%-40s    %s", File.basename(todo_expected), out_path)
  FileUtils.cp todo_expected, out_path, verbose: true
end
