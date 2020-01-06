#!/usr/bin/env ruby

##
# Run ps on the remote hosts to show which tooo runner processes are running by grep for "[b]undle".
#
# See https://unix.stackexchange.com/a/74186 for an explanation of this grep pattern
#

require_relative '../lib/guardian_checker'

HOSTS = %w{ guardian01.library.upenn.int guardian02.library.upenn.int guardian03.library.upenn.int guardian04.library.upenn.int }

HOSTS.each do |host|
  puts "===== Jobs running on: #{host} ====="
  puts `ssh #{host} 'ps -ef | grep "[b]undle"'`
  puts
end
