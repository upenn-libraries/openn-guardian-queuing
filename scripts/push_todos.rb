#!/usr/env/bin ruby

require_relative '../lib/hosts'
require_relative '../lib/utils'
# send tar-gzipped *.todo files to remote server and add them to the docker
# container's /todos directory
#
# scp files to g01, g02
#
# untar files
# copy files into docker container
# start guardian process on server for group LARGE, A, B, C:
#
#   g01 LARGE
#   g01 A
#   g01 B
#   g01 C

CMD = File.basename __FILE__

def usage
  puts "Usage: #{CMD} SERVER GROUP TODOS_TGZ"
  puts
  puts "Servers:  #{HOSTS.keys.join ', '}"

  HOSTS.each do |code,server|
    puts "   #{code}: #{server}"
  end
  puts
end # def usage

def todo_dirname archive
  return unless valid_gzip? archive
  file = `tar tf #{archive} | head -1`
  dir =  File.dirname file
  return '.' if dir.empty?
  dir
end

host_code, group_code, gzipped_todos = ARGV
host_data = find_host host_code
die "Please enter a valid SERVER"             unless host_data
die "Please enter a valid GROUP"              unless valid_group? host_code, group_code
die "Please enter a valid todo file archive"  unless valid_gzip? gzipped_todos

# remote name for the archive with timestamp appended
gzip_remote = "#{File.basename(gzipped_todos, '.tgz')}-#{Time.new.strftime '%Y%m%d-%H%M%S'}.tgz"

# copy files to server
host = host_data[:host]
cmd = "scp #{gzipped_todos} #{host}:#{gzip_remote}"
exit 1 unless run_command cmd

# copy files to docker container tmp dir
cmd = %Q{ssh #{host} 'docker cp #{gzip_remote} $(docker ps -q -f name=guardian_guardian):/tmp/'}
exit 1 unless run_command cmd

# unzip the files into /tmp in the container
cmd = %Q{ssh #{host} 'docker exec -t $(docker ps -q -f name=guardian_guardian) sh -c "tar xvf /tmp/#{gzip_remote} --directory=/tmp"'}
# cmd = "ssh #{host} 'docker exec -t $(docker ps -q -f name=guardian_guardian) tar xvf /tmp/#{gzip_remote} --directory=/tmp '"
exit 1 unless run_command cmd

# copy the files into place
tmp_todos_dir  = File.join '/tmp', todo_dirname(gzipped_todos)
cmd = %Q{ssh #{host} 'docker exec -t $(docker ps -q -f name=guardian_guardian) sh -c "cp -v #{tmp_todos_dir}/#{group_code}*.todo /todos/"'}
exit 1 unless run_command cmd

# clean up the remote archive
cmd = "ssh #{host} 'docker exec -t $(docker ps -q -f name=guardian_guardian) rm -v /tmp/#{gzip_remote}'"
cmd = %Q{ssh #{host} 'docker exec -t $(docker ps -q -f name=guardian_guardian) sh -c "rm -v /tmp/#{gzip_remote}"'}
exit 1 unless run_command cmd

# remove the todo files
cmd = %Q{ssh #{host} 'docker exec -t $(docker ps -q -f name=guardian_guardian) sh -c "rm -v #{tmp_todos_dir}/*.*"'}
exit 1 unless run_command cmd

# remove the remote todo file dir
cmd = %Q{ssh #{host} 'docker exec -t $(docker ps -q -f name=guardian_guardian) sh -c "rmdir -v #{tmp_todos_dir}"'}
exit 1 unless run_command cmd

