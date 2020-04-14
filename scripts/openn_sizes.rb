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

# This is the 'Completed' tab from the Glacier_Priorities spreadsheet.
# We use it for list of directories already in Glacier
DIRS_LIST = File.expand_path '../../data/Glacier_Priorities-Completed.csv', __FILE__
DIRS_IN_GLACIER = CSV.readlines(DIRS_LIST, headers: true).flat_map { |row|
  todo_base = row['todo_base']
  group = row['group']
  if group.nil? || group.strip.empty?
    # These are the walters MSS. 
    # For each of these list the two possible paths that might occur in the 
    # spreadsheet.
    parts = todo_base.split(/_/, 2)
    [ "0020/Data/WaltersManuscripts/#{parts[1]}",
      "0020/Data/OtherCollections/#{parts[1]}" ]
  else
    todo_base.sub /_/, '/'
  end
}

# This is the 'Glacier_sizes' tab from the Glacier_Priorities spreadsheet.
# We use it for the list of all the objects already accounte for.
ALREADY_ACCOUNTED_FOR_CSV = File.expand_path '../../data/Glacier_Priorities-Glacier_sizes.csv', __FILE__
ALREADY_ACCOUNTED_FOR = CSV.readlines(ALREADY_ACCOUNTED_FOR_CSV, headers: true).flat_map { |row| 
  todo_base = row['Key']
  if row['STATUS'] =~ %r{Walters}i
    # These are the walters MSS. 
    # For each of these list the two possible paths that might occur in the 
    # spreadsheet.
    parts = todo_base.split(/_/, 2)
    [ 
      "0020/Data/WaltersManuscripts/#{parts[1]}",
      "0020/Data/OtherCollections/#{parts[1]}"
    ]
  else
    todo_base.sub /_/, '/'
  end
}

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

# Go through all the contents CSVs and pull only those directories not
# already in Glacier and not already listed in Glacier Sizes. Print out their sizes
# Key    repo    Path extension    Priority    Group    Repo Name    size    size_gb    folder    In Glacier    Size in Glacier    STATUS    Notes
headers = %q{Key,repo,Path extension,Priority,Group,Repo Name,size,size_gb,folder,In Glacier,Size in Glacier,STATUS,Notes}.split %r{,}
count = 0
CSV headers: true do |out_csv|
  out_csv << headers
  CONTENTS_CSVS.each do |csv|
    CSV.foreach csv, headers: true do |row|
      path = row['path']
      next if ALREADY_ACCOUNTED_FOR.include? path
      next if DIRS_IN_GLACIER.include? path
      repo    = path.split('/').first
      folder  = path.split('/').last
      key     = "#{repo}_#{folder}"
      size    = get_size path
      size_gb = size_in_gb size

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
