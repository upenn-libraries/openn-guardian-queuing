#!/usr/bin/env ruby


require_relative '../lib/utils'
require_relative '../lib/hosts'
# Script to run a guardian process for a given host and todo file group


CMD = File.basename __FILE__

def usage
  puts "Usage: #{CMD} SERVER GROUP"
  puts
  puts "Servers:  #{HOSTS.keys.join ', '}"

  HOSTS.each do |code,server|
    puts "   #{code}: #{server}"
  end
  puts
end


host_code, group_code = ARGV
host_data = find_host host_code
die "Please enter a valid SERVER"             unless host_data
die "Please enter a valid GROUP"              unless valid_group? host_code, group_code
host = host_data[:host]

# check to see if the job is running
cmd = %Q{ ssh #{host} 'ps -ef | grep "[b]undle exec ruby guardian-glacier-transfer /todos/#{group_code}0\\*\\.todo"' }
puts `#{cmd}`
die "Todo job for #{group_code} on #{host} is already running" if $?.exitstatus == 0

# start the todo job
cmd = %Q{ ssh #{host} 'docker exec -d $(docker ps -q -f name=guardian_guardian) sh -c "cd /usr/src/app; bundle exec ruby guardian-glacier-transfer /todos/#{group_code}0*.todo >> /zip_workspace/openn-#{group_code}-#{Time.new.strftime '%Y%m%d-%H%M%S'}.log 2>&1"' }

puts cmd
# exit
exit 1 unless run_command cmd
