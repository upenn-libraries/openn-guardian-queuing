HOSTS = {
    g01: {
        host:   'guardian01.library.upenn.int',
        groups: %w{ LARGE A }
    },
    g02: {
        host:   'guardian02.library.upenn.int',
        groups: %w{ B C }
    }
}

##
# Return the hash of data associated with +host_code+; for example,
#
#     {
#         host:   'guardian01.library.upenn.int',
#         groups: %w{ LARGE A }
#     }
#
# @param [String] :host_code the server host code; e.g., +g01+
def find_host host_code
  return unless host_code
  normal_code = host_code.to_s.strip.downcase
  return if normal_code.empty?
  HOSTS[normal_code.to_sym]
end