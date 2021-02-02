#!/usr/bin/env ruby

################################################################################
#
# Script to get size data for all OPenn docs not yet in Glacier
#
# Important: Run this script on the OPenn server. It relies on local
#            paths on OPenn.
#
################################################################################
require 'csv'
require 'set'

abort "Please set the OPENN_ROOT_DIR environment variable" unless ENV['OPENN_ROOT_DIR']

DATA_DIR = File.join ENV['OPENN_ROOT_DIR'], 'Data'
unless File.directory? DATA_DIR
  STDERR.puts "ERROR: You don't appear to be on the OPenn server"
  STATUS.puts "Please run this script on the OPenn host"
  exit 1
end

CONTENTS_CSVS=Dir["#{DATA_DIR}/[0-9][0-9][0-9][0-9]_contents.csv"]

# Get the mapping of all repos (e.g., '0001') and their names
# (e.g., 'University of Pennsylvania Libraries, Lawrence J. Schoenberg
# Manuscripts')
REPO_LIST = File.join DATA_DIR, 'collections.csv'
REPO_NAMES = CSV.readlines(REPO_LIST, headers: true).inject({}) do |h,row|
  unless row['repository_id'] == 'N/A'
    h[row['repository_id']] = row['collection_name']
  end
  h
end

RENAMED_FOLDERS_CSV = File.expand_path('../../data/renamed_folders.csv', __FILE__)
RENAMED_FOLDERS = CSV.readlines(RENAMED_FOLDERS_CSV, headers:true).inject({}) do |h,row|
  old_repo_folder  = "#{row['repo']}_#{row['oldfolder']}"
  new_repo_folder  = "#{row['repo']}_#{row['newfolder']}"
  h[old_repo_folder] = new_repo_folder
  h[new_repo_folder] = old_repo_folder
  h
end

GLACIER_SIZES_CSV = File.expand_path '../../data/Glacier_Priorities-Glacier_sizes.csv', __FILE__
# map from the repo + folder to the key for an object
KEY_MAP = CSV.readlines(GLACIER_SIZES_CSV, headers: true).inject({}) do |h,row|
  key                             = row['Key']
  repo_folder                     = "#{row['repo']}_#{row['folder']}"
  h[repo_folder]                  = key
  # make sure we have both names for renamed folders
  h[RENAMED_FOLDERS[repo_folder]] = key if RENAMED_FOLDERS.include? repo_folder
  h
end

def get_size path
  full_path = File.join DATA_DIR, path
  output    = %x{ du -s #{full_path} }
  output.split.first
end

def size_in_gb size, precision = 3
  gb = size.to_f / (1024**2)
  gb.round precision
end

def path_extension path
  parts  = path.split '/'
  return if parts.size == 2
  "/#{parts[1]}/#{parts[2]}/"
end

GROUPS = %w{ A B C }
@ticker = GROUPS.size
def group size_gb
  return 'LARGE' if size_gb >= 100
  g = GROUPS[@ticker % 3]
  @ticker += 1
  g
end

def new_object? repo, folder
  return false if KEY_MAP.include? "#{repo}_#{folder}"
  true
end # def new_object? repo, folder

def fetch_key repo, folder
  KEY_MAP[[repo, folder].join '_']
end

# Go through all the contents CSVs and pull only those directories not
# already in Glacier and not already listed in Glacier Sizes. Print out their sizes
# Key    repo    Path extension    Priority    Group    Repo Name    size    size_gb    folder    In Glacier    Size in Glacier    STATUS    Notes
headers = %q{Key,repo,Path extension,Priority,Group,Repo Name,size,size_gb,folder,In Glacier,Size in Glacier,STATUS,Notes}.split %r{,}
count = 0
CSV headers: true do |out_csv|
  out_csv << headers
  CONTENTS_CSVS.each do |csv|
    # document_id,path,title,metadata_type,created,updated
    # 1,0001/ljs103,Reproduction of Sienese book covers.,TEI,2014-11-03T23:13:18+00:00,2015-04-22T15:17:04+00:00
    # 2,0001/ljs201,Evangelista Torricelli letter to Marin Marsenne,TEI,2014-11-03T23:38:42+00:00,2015-04-22T15:17:05+00:00
    # 3,0001/ljs255,Manuscript leaf from De casibus virorum illustrium,TEI,2014-11-03T23:39:46+00:00,2019-10-15T18:09:21+00:00
    # 4,0001/ljs489,Nawaz letter with seal,TEI,2014-11-03T23:40:23+00:00,2015-04-22T15:17:07+00:00
    # 5,0001/ljsmisc1,Sluby family indenture :,TEI,2014-11-03T23:41:42+00:00,2015-04-22T15:17:07+00:00
    # 6,0001/ljsmisc2,Timothy Stedham indenture :,TEI,2014-11-03T23:42:45+00:00,2015-04-22T15:17:07+00:00
    # 7,0001/ljsmisc3,John and Mary Hoffman indenture :,TEI,2014-11-03T23:43:16+00:00,2015-04-22T15:17:07+00:00
    # 8,0001/ljsmisc4,Jacob Richman survey :,TEI,2014-11-03T23:43:47+00:00,2015-04-22T15:17:07+00:00
    # 9,0001/ljsmisc5,Subscription for cutting a channel from Salem Creek :,TEI,2014-11-03T23:43:59+00:00,2015-04-22T15:17:07+00:00
    CSV.foreach csv, headers: true do |row|
      path      = row['path']
      repo      = path.split('/').first
      folder    = path.split('/').last
      next unless new_object? repo, folder
      key       = fetch_key(repo,folder) || "#{repo}_#{folder}"
      size      = get_size path
      size_gb   = size_in_gb size

      new_row                   = {}
      new_row['Key']            = key
      new_row['repo']           = repo
      new_row['Path extension'] = path_extension path
      new_row['Group']          = group size_gb
      new_row['Repo Name']      = REPO_NAMES[repo]
      new_row['size']           = size
      new_row['size_gb']        = size_gb
      new_row['folder']         = folder

      out_csv << new_row
    end
  end
end
