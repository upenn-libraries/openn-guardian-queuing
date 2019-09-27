require 'date'

class RunData
  attr_reader :file
  attr_reader :time

  def initialize file, time_string
    @file = file
    @time = DateTime.parse time_string
  end

  def todo_base
    file.sub(/^[A-Z]+\d+_/, '').sub(/\.[-\w]+$/, '')
  end

  def to_s
    "RunData: @file=#{file} @time=#{time}"
  end
end

class Batch
  attr_reader :successes
  attr_reader :failures
  attr_reader :others
  attr_reader :processing
  attr_reader :group
  attr_reader :host

  def initialize host, group
    @host       = host
    @group      = group
    @successes  = []
    @failures   = []
    @processing = []
    @others     = []
  end

  def add_run file, time_string
    case file
    when /SUCCESS/
      @successes << RunData.new(file, time_string)
    when /FAIL/
      @failures << RunData.new(file, time_string)
    when /processing/
      #@processing << RunData.new(file,time_string)
    else
      @others << RunData.new(file,time_string)
    end
  end

  def success_files
    successes.map &:file
  end

  def failure_files
    failures.map &:file
  end

  def processing_files
    processing.map &:file
  end

  def other_files
    others.map &:file
  end

  def last_changed
    [successes, failures, processing, others].flatten.sort { |a,b| a.time <=> b.time }.last
  end
end

module GuardianChecker

  def self.read_all_hosts hosts
    batch_stats = {}
    hosts.map do |host|
      GuardianChecker::read_host(host).each do |batch|
        batch_stats[batch.group] = batch
      end
    end
    batch_stats
  end

  def self.read_host host
    batch_stats = {}
    # ssh g03 "sudo docker ps | grep guardian_guardian" | awk '{ print $1 }'
    ps_line = `ssh #{host} "sudo docker ps | grep guardian_guardian"`.strip
    container_id = ps_line.split.first
    # ssh g03 "sudo  docker exec ${hash} ls -l /todos" | grep SUCCESS
    ls_lines = `ssh #{host} "sudo docker exec #{container_id} ls -l --time-style=long-iso /todos"`.split($/).map &:strip
    ls_lines.each do |line|
      next if line =~ /^total \d+$/
      file = line.split.last
      file =~ /\A([A-Z]+)0/
      code = "#{$1}"
      next if code.to_s.empty?
      time_string = line.split[5,2].join ' '
      batch_stats[code] ||= Batch.new host, code
      batch_stats[code].add_run file, time_string
    end
    batch_stats.values
  end
end