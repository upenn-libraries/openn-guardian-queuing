#!/usr/env/bin ruby

require 'csv'
require 'yaml'

################################################################################
#
# Convert input CSV to guardian_manifest.rb YAML.
#
# Input CSV should have columns: 'repo', 'Path extension', 'Repo name',
# 'folder'
#
# Input format:
#
# Key,repo,Path extension,Priority,Group,Repo Name,size,size_gb,folder,STATUS,Notes
# 0014_html,0014,,1,LARGE,Private Collection A,20,0,html,,
# 0014_GalenSyriacPalimpsest,0014,,1,LARGE,Private Collection A,"372,303,892",355.057,GalenSyriacPalimpsest,,
# 0014_ArchimedesPalimpsest,0014,,1,LARGE,Private Collection A,"733,734,829",699.744,ArchimedesPalimpsest,,
# 0020_html,0020,Data/OtherCollections,1,A,The Walters Art Museum,"2,613",0.002,html,,
# 0020_PC1,0020,Data/OtherCollections,1,A,The Walters Art Museum,"9,124,724",8.702,PC1,,
# 0020_PC10,0020,Data/OtherCollections,1,LARGE,The Walters Art Museum,"120,244,971",114.675,PC10,,
# 0020_PC11,0020,Data/OtherCollections,1,A,The Walters Art Museum,"34,810,998",33.198,PC11,,
# 0020_PC2,0020,Data/OtherCollections,1,A,The Walters Art Museum,"24,952,886",23.797,PC2,,
# 0020_PC3,0020,Data/OtherCollections,1,A,The Walters Art Museum,"42,493,355",40.525,PC3,,
# 
# Output format:
#
#  ---
#  source: rsync://openn.library.upenn.edu/OPenn/Data/0023
#  workspace: /zip_workspace
#  compressed_destination: /zip_workspace
#  compressed_extension: zip
#  verification_destination: /zip_workspace
#  verification_sample_size: ALL
#  vault: stronghold
#  application: openn
#  method: rsync
#  todo_prefix: '0023_'
#  description_values:
#    owner: demery
#    repository: Free Library of Philadelphia
#    openn_repo_id: '0023'
#  directive_names:
#     - lewis_e_m_033_004
#     - lewis_e_m_033_005
#     - lewis_e_m_007_005
#     - lewis_e_m_033_011
#     - lewis_e_m_015_009
#
################################################################################

base_yml = <<EOF
---
source:
workspace: /zip_workspace
compressed_destination: /zip_workspace
compressed_extension: zip
verification_destination: /zip_workspace
verification_sample_size: ALL
vault: openn
application: openn
method: rsync
todo_prefix:
description_values:
  owner: demery
  repository:
  openn_repo_id: 
  source:
directive_names:
EOF


# Get the CSV input file
file = ARGV.shift

class Repo
  attr_accessor :repo_id, :path_extension, :name, :folders

  BASE_SOURCE_URL = 'rsync://openn.library.upenn.edu/OPenn/Data'

  def initialize repo_id:, path_extension:, name:
    @repo_id        = repo_id
    @path_extension = path_extension
    @name           = name
    @folders        = []
  end # def initialize repo:, path_extension:, name:

  ##
  # Add a folder to the list.
  #
  # @param [String] folder name of the folder
  # @return [Repo] self
  def << folder
    @folders << folder && self
  end

  ##
  # Return the URI for the source directory on OPenn.
  #
  # Basic version is ++BASE_SOURCE_URL++ + ++repo_id++:
  #
  #     'rsync://openn.library.upenn.edu/openn/data' + '0009'
  #         => 'rsync://openn.library.upenn.edu/openn/data/0009'
  #
  # If there's a ++path_extension++, that's appended:
  #
  #     'rsync://openn.library.upenn.edu/OPenn/Data' + '0020' + 'Data/OtherCollections'
  #         => 'rsync://openn.library.upenn.edu/OPenn/Data/0020/Data/OtherCollections'
  #
  # @return [String] URI for the source directory on OPenn
  def source
    return BASE_SOURCE_URL + '/' + repo_id unless path_extension 
    BASE_SOURCE_URL + '/' + repo_id + '/' + path_extension.sub(%r{^\s*/}, '').sub(%r{/\s*$}, '') 
  end # def source
end

repos = {}

# Build all the Repo objects
CSV.foreach file, headers: true do |row|
  repo_id = row['repo']
  next unless repo_id
  repos[repo_id] ||= Repo.new repo_id: repo_id, path_extension: row['Path extension'], name: row['Repo Name']
  repos[repo_id] << row['folder']
end

# Create the YAML files.
repos.each do |repo_id, repo|
  hash                                        = YAML.load base_yml
  hash['source']                              = repo.source
  hash['todo_prefix']                         = "#{repo.repo_id}_"
  hash['description_values']['repository']    = repo.name
  hash['description_values']['openn_repo_id'] = repo.repo_id
  hash['description_values']['source']        = repo.source
  hash['directive_names']                     = repo.folders
  out_file = File.expand_path "../../tmp/inventory_#{repo.repo_id}.yml", __FILE__
  File.open(out_file, 'wb+') { |f| f.puts hash.to_yaml }
  puts "Wrote: #{out_file}"
end

