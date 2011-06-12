#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'rubygems'
require 'shellwords'
require 'mcp/common/mcast_exception'
require 'mcp/tools'

module MediacastProducer
  module Tools
    class Base
      def self.inherited(subclass)
        MediacastProducer::Tools.add_tool_class(subclass)
      end

      def initialize(path_to_tool=nil, min_version=nil, max_version=nil)
        @tool_path = path_to_tool
        @tool_version = nil
        @required_min_version = min_version
        @required_max_version = max_version
        @version_checked = nil
      end

      def name
        self.class.name.split("::").last.downcase
      end

      def tool_path
        return @tool_path unless @tool_path.nil?
        path = lookup_path.chomp!
        raise McastToolException.new, self.class.to_s + ": could not lookup tool path: #{name}" if path.nil? || path == "" || !File.executable?(path)
        path = Pathname.new(path).realpath.to_s
        log_notice("path to #{name}: #{path}")
        @tool_path = path
      end

      def tool_version
        return @tool_version unless @tool_version.nil?
        ver = lookup_version.chomp!
        raise McastToolException.new, self.class.to_s + ": could not lookup tool version: #{name}" if ver.nil? || ver == ""
        log_notice("#{name} version: #{ver}")
        @tool_version = ver
      end

      def lookup_path
        raise McastToolException.new, self.class.to_s + ": Missing 'lookup_path' implementation."
      end

      def lookup_version
        raise McastToolException.new, self.class.to_s + ": Missing 'lookup_version' implementation."
      end

      def check_version
        return @version_checked unless @version_checked.nil?
        return (@version_checked = true)  if @required_min_version.nil? && @required_max_version.nil?
        return (@version_checked = false) if tool_version.nil?
        ver = Gem::Version.new(tool_version)
        unless @required_min_version.nil?
          min = Gem::Version.new(@required_min_version)
          unless min <= ver
            log_error(self.class.to_s + ": minimum version #{@required_min_version} requirement failed for version #{tool_version}")
            return (@version_checked = false)
          end
        end
        unless @required_max_version.nil?
          max = Gem::Version.new(@required_max_version)
          log_crit_and_exit(self.class.to_s + ": invalid requirement version maximum #{@required_max_version} < minimum #{@required_min_version}", -1) unless @required_min_version.nil? || min <= max
          unless ver <= max
            log_error(self.class.to_s + ": maximum version #{@required_max_version} requirement failed for version #{tool_version}")
            return (@version_checked = false)
          end
        end
        log_notice(self.class.to_s + ": passed version check")
        return (@version_checked = true)
      end

      def command_line(verbose=false)
        [tool_path]
      end

      def valid?
        return (tool_path.nil? || !check_version) ? nil : self
      end

      def run(*arguments)
        log_crit_and_exit("failed to run tool with arguments, due to unsatisfied dependencies",ERR_TOOL_FAILURE) unless valid?
        log_notice("running: #{tool_path} #{arguments.join(' ')}")
        arguments.unshift(tool_path)
        fork_exec_and_wait(*arguments)
      end

      def log_crit(msg)
        ASLLogger.crit(self.class.to_s + ": " + msg)
      end

      def log_error(msg)
        ASLLogger.error(self.class.to_s + ": " + msg)
      end

      def log_warn(msg)
        ASLLogger.warn(self.class.to_s + ": " + msg)
      end

      def log_notice(msg)
        ASLLogger.notice(self.class.to_s + ": " + msg)
      end

      def log_info(msg)
        ASLLogger.info(self.class.to_s + ": " + msg)
      end

      def log_debug(msg)
        ASLLogger.debug(self.class.to_s + ": " + msg)
      end

      def log_crit_and_exit(msg, status_code = -1)
        ASLLogger.crit(self.class.to_s + ": " + msg)
        if $no_fail
          ASLLogger.notice(self.class.to_s + ": " + "No fail flag was set. Exiting with exit code '0'.")
          exit(0)
        else
          exit(status_code)
        end
      end
    end
  end
end
