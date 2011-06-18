#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require '/usr/lib/podcastproducer/actions'
require 'cgi' # this fixes "NameError: uninitialized constant CGI" issue from the library above

module PodcastProducer
  module Actions
    def self.add_action_class(action_class)
      log_notice("adding action #{action_class}")
      @@action_classes << action_class
    end

    def self.load_actions
      #      Dir["/usr/lib/podcastproducer/actions/*.rb"].each do |path|
      #        name = File.join(File.dirname(path), File.basename(path, ".rb"))
      #        require name
      #      end
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

def check_input_file_exclude_dir(input_path)
  log_crit_and_exit("Input file was not specified.", -1) if input_path.nil?
  log_crit_and_exit("Input file '#{input_path}' does not exist.", -1) unless File.exists?(input_path)
  log_crit_and_exit("Input file '#{input_path}' is a directory.", -1) if File.directory?(input_path)
  log_crit_and_exit("Input file '#{input_path}' is not readable.", -1) unless File.readable?(input_path)
end

def check_output_file_exclude_dir(output_path, remove_existing=false)
  log_crit_and_exit("Output filepath was not specified.", -1) if output_path.nil?
  log_crit_and_exit("Output folder '#{File.dirname(output_path)}' does not exist.", -1) unless File.exists?(File.dirname(output_path))
  log_crit_and_exit("Output folder '#{File.dirname(output_path)}' is not a directory.", -1) unless File.directory?(File.dirname(output_path))
  log_crit_and_exit("Output folder '#{File.dirname(output_path)}' is not writable.", -1) unless File.writable?(File.dirname(output_path))

  if File.exists?(output_path)
    if remove_existing
      log_warn("Removing file that already exists at the output file path '#{output_path}'.")
      FileUtils.rm_f(output_path)
    else
      log_crit_and_exit("Output file '#{output_path}' already exists and is a directory.", -1) if File.directory?(output_path)
      log_crit_and_exit("Output file '#{output_path}' already exists.", -1)
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

def fork_exec_and_return_pid(*args)
  pid = fork { exec(*args) }
  return false unless pid
  # Process.detach(pid)
  pid
end

def fork_exec_and_wait(*args)
  pid = fork_exec_and_return_pid(*args)
  return false unless pid
  Process.waitpid(pid)
  return false unless $?.exited? && $?.exitstatus == 0
  return true
end

def fork_chain_and_return_pids(*chain)
  r = 0
  w = 1
  pipes = []
#  errs = []
  pids = []
  (1..chain.length).each {pipes << IO.pipe}
#  (1..chain.length).each {errs << IO.pipe}
  i = 0
  l = chain.length - 1
  chain.each do |args|
    pid = fork do
      if l > 0
        log_notice("test #{i} of #{l}")
#        pipes[i-1][w].close if i > 0
        pipes[i][r].close # if i < l
#        errs[i][r].close
        STDIN.reopen(pipes[i-1][r]) if i > 0
        STDOUT.reopen(pipes[i][w]) if i < l
#        STDERR.reopen(errs[i][w])
      end
      exec(*args)
    end
    if l > 0
      pipes[i-1][r].close if i > 0
      pipes[i][w].close # if i < l
      pipes[i][r].close if l > 0 && i == l
#      errs[i][w].close
    end
    break unless pid
    pids << pid
    i = pids.length
  end
  return pids if pids.length==chain.length
  pids.each do |pid|
    Process.kill('HUP', pid)
    Process.waitpid(pid)
  end
  return false
end

def fork_chain_and_wait(*chain)
  pids = fork_chain_and_return_pids(*chain)
  return false unless pids
  result = true
  pids.each do |pid|
    Process.waitpid(pid)
    result = false unless $?.exited? && $?.exitstatus == 0
  end
  return result
end
