#!/usr/bin/env ruby

require 'date'
require 'csv'

require_relative '../lib/guardian_checker'

def usage
  STDERR.puts "Usage: #{File.basename __FILE__} [SUCCESS|FAILURE|OTHER|LAST_TOUCHED]"
end

VALID_RUN_TYPES = %w{ success failure other last_touched }
##
# Returns all run types matching the input value (case-insensitive), beginning
# with the input +run_type+ value.
#
# @param [String] run_type user input run type value
# @return [Array] all run types matching the input value
def matching_run_types run_type
  return [] if run_type.to_s.empty?
  VALID_RUN_TYPES.grep %r{^#{run_type.to_s.strip}}i
end

def valid_run_type? run_type, verbose: false
  types = matching_run_types run_type
  return true if types.size == 1
  if types.empty?
    msg = "INVALID RUN_TYPE: '#{run_type}'; expected: #{VALID_RUN_TYPES.join ', '}"
  elsif types.size > 1
    msg = "AMBIGUOUS RUN_TYPE: '#{run_type}'; expected: #{VALID_RUN_TYPES.join ', '}"
  end
  STDERR.puts msg if verbose
end

def get_run_files batch, run_type
  case run_type
  when 'success'
    batch.successes
  when 'failure'
    batch.failures
  when 'other'
    batch.others
  when 'last_touched'
    [batch.last_changed]
  else
    []
  end
end

HOSTS = %w{ guardian01.library.upenn.int guardian02.library.upenn.int guardian03.library.upenn.int guardian04.library.upenn.int }

input_type = ARGV.first || 'SUCCESS'

# Hard-coded for now; consider making this a CLI option
options = { verbose: true }

unless valid_run_type? input_type, verbose: options[:verbose]
  usage
  abort
end

run_type = matching_run_types(input_type).first

batch_stats = GuardianChecker::read_all_hosts HOSTS

CSV do |csv|
  csv << %w{ host group file todo_base time }
  batch_stats.each do |group, batch|
    get_run_files(batch, run_type).each do |data|
      csv << [batch.host, group, data.file, data.todo_base, data.time]
    end
  end
end
