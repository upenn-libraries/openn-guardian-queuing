
##
# Return true if +host_code+ is valid and +group_code+ is listed in its groups.
#
# @param [String] :host_code the server host code; e.g., +g01+
# @param [String] :group_code the prefix for the todo file group; e.g., +C+
#                 for +C00066_0002_kcajs_rar_ms123.todo+, or +LARGE+ for
#                 +LARGE00001_0020_W535.todo+
# @raise [Boolean] +true+ if +host_code+ is valid and +group_code+ is listed
#                   in its +:groups+
def valid_group? host_code, group_code
  return unless group_code
  host_data = find_host host_code
  return unless host_data

  host_data[:groups].include? group_code
end

##
# Print +msg+ and exit with status +1+. If function +usage+ is defined
# invoke it.
#
# @param [String] :msg the error message
def die msg
  puts msg
  usage if defined? usage
  exit 1
end

##
# Test the file to see that it exists and is a valid gzip file.
#
# @param [String] :archive path to the archive file
# @return [Boolean] true if archive contents can be listed
def valid_gzip? archive
  return unless archive
  return unless File.exist? archive
  `tar tf #{archive} >/dev/null`
  $?.exitstatus == 0
end

##
# Run the command +cmd+.
def run_command cmd, silent=false
  puts "Running command: #{cmd}" unless silent

  if silent
    `#{cmd}`
  else
    puts `#{cmd}`
  end

  return true if $?.exitstatus == 0

  puts "Error running command '#{cmd}'" unless silent
  false
end
