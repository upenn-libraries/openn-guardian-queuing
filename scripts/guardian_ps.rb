#!/usr/bin/env ruby

require_relative '../lib/guardian_checker'

HOSTS = %w{ guardian01.library.upenn.int guardian02.library.upenn.int guardian03.library.upenn.int guardian04.library.upenn.int }

HOSTS.each do |host|
  puts "===== #{host} ====="
  puts `ssh #{host} "sudo docker ps"`
  puts
end