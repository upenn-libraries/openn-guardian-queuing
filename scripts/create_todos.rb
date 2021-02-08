#!/usr/bin/env ruby

require_relative '../lib/hosts'
require_relative '../lib/utils'
require 'fileutils'
require 'logger'

# Assumed: you have an up-to-date sizes.csv for all the files not yet on the list.
# Take this file as an argument; create and order all the needed todos, then push
# these to the server
CMD = File.basename __FILE__
TIMESTAMP = Time.now.strftime '%Y%m%dT%H%M%Z'

THIS_DIR = File.expand_path '..', __FILE__
PROJECT_ROOT = File.dirname THIS_DIR
TMP_DIR = File.join PROJECT_ROOT, 'tmp'
TODO_DIR = File.join TMP_DIR, "todo-#{TIMESTAMP}"
LOGGER = Logger.new STDOUT
LOGGER.level = :INFO
def usage
  puts "Usage: #{CMD} sizes.csv"
end

sizes_csv = ARGV.shift

die "Please provide a path to sizes.csv" unless sizes_csv
die "Can't find #{sizes_csv}" unless File.file? sizes_csv

LOGGER.info(CMD) { "Cleaning up earlier jobs" }

# clean up
FileUtils.rm_f File.join(TMP_DIR, '*.yml'), verbose: true
FileUtils.rm_f File.join(TMP_DIR, '*.yml.csv'), verbose: true
FileUtils.rm_f File.join(TODO_DIR, '*'), verbose: true

LOGGER.info(CMD) { "Build inventory YAML files from #{sizes_csv}" }
cmd = %Q{ruby #{File.join THIS_DIR, 'build_inventory.rb'} #{sizes_csv}}
exit 1 unless run_command cmd

LOGGER.info(CMD) { "Build guardian manifest CSVs from inventory YMLs" }

guardian_manifest_dir = File.join TMP_DIR, 'guardian_manifest'
unless Dir.exist? guardian_manifest_dir
  LOGGER.info(CMD) { "Pulling guardian manifest from gitlab" }
  cmd = %Q{git clone ssh://git@gitlab.library.upenn.edu:2223/digital-repository/guardian_manifest.git #{guardian_manifest_dir}}
  exit status 1 unless run_command
  Dir.chdir guardian_manifest_dir do
    cmd = 'bundle'
    exit 1 unless run_command cmd
  end
end

Dir.chdir guardian_manifest_dir do
  yml_files = Dir[File.join TMP_DIR, '*.yml']
  yml_files.each do |yml|
    cmd = %Q{bundle exec ruby guardian_manifest.rb #{yml} #{yml}.csv #{TMP_DIR}}
    exit 1 unless run_command cmd
  end
end

LOGGER.info(CMD) { "Create individual todo files from guardian manifest CSVs" }

csv_to_yaml_dir = File.join TMP_DIR, 'csv_to_yaml'
unless Dir.exist? csv_to_yaml_dir
  LOGGER.info(CMD) { "Pulling csv_to_yaml from gitlab" }
  cmd = %Q{git clone ssh://git@gitlab.library.upenn.edu:2223/utils/csv_to_yml.git #{csv_to_yaml_dir}}
  exit 1 unless run_command cmd
  Dir.chdir csv_to_yaml_dir do
    cmd = 'bundle'
    exit 1 unless run_command cmd
  end
end

Dir.mkdir TODO_DIR unless Dir.exist? TODO_DIR

Dir.chdir csv_to_yaml_dir do
  csv_files = Dir[File.join TMP_DIR, '*.yml.csv']
  csv_files.each do |csv|
    cmd = %Q{bundle exec ruby csv_to_yml.rb #{csv} todo #{TODO_DIR}}
    exit 1 unless run_command cmd
  end
end

LOGGER.info(CMD) { "Sort the todo files into groups for deployment" }

cmd = %Q{ruby #{File.join THIS_DIR, 'sort_todo_files.rb'} #{sizes_csv} #{TODO_DIR}}
exit 1 unless run_command cmd

LOGGER.info(CMD) { "Tar-gzip the sorted todo files for pushing to the servers" }
tgz_file = "#{TODO_DIR}.tgz"
Dir.chdir TMP_DIR do
  cmd = %Q{tar czvf #{tgz_file} #{File.basename TODO_DIR}/**}
  exit 1 unless run_command cmd
end

puts <<~EOF
###############################################################################
SUCCESS! New *.todo files have been created for #{sizes_csv}.
These have been written to:

  #{tgz_file}

Now you should:

1. Run 'ruby scripts/push_todos.rb SERVER GROUP #{tgz_file}';
   for g01 {LARGE,A}; and g02 {B,C}.

2. Run 'ruby scripts/guardian_run.rb SERVER GROUP'; for
   g01 {LARGE,A}; and g02 {B,C}.
###############################################################################

EOF
