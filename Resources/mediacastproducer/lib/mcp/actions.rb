#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'actions'
require 'cgi' # this fixes "NameError: uninitialized constant CGI" issue from the library above

module PodcastProducer
  module Actions
  
    def self.load_actions
      Dir["/usr/lib/podcastproducer/actions/*.rb"].each do |path|
        name = File.join(File.dirname(path), File.basename(path, ".rb"))
        require name
      end
#      puts MCP_LIB
      Dir[File.join(File.expand_path(MCP_LIB), "mcp/actions/*.rb")].each do |path|
#        puts path
        name = File.join(File.dirname(path), File.basename(path, ".rb"))
#        puts name
        require name
      end
    end
    
  end
end

def check_input_and_output_paths_are_not_equal(input, output)
  if (File.expand_path(input) == File.expand_path(output))
    log_crit_and_exit("Cannot modify files in place.",ERR_EDITING_INPLACE)
  else
    return output
  end
end

def fork_exec_and_wait(*args)
  pid = fork { exec(*args) }
  return false unless pid
  Process.waitpid(pid)
  return false unless $?.exited? && $?.exitstatus == 0
  return true
end

