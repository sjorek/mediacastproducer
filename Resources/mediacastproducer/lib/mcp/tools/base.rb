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
        @path = path_to_tool
        @version = nil
        @required_min_version = min_version
        @required_max_version = max_version
      end

      def path
        return @path unless @path.nil?
        @path = lookup_path
        raise McastToolException.new, self.class.to_s + ": could not lookup tool path: #{name}" if @path.nil?
        @path
      end

      def version
        return @version unless @version.nil?
        @version = lookup_version
        raise McastToolException.new, self.class.to_s + ": could not lookup tool version: #{name}" if @version.nil?
        @version
      end

      def lookup_path
        raise McastToolException.new, self.class.to_s + ": Missing 'lookup_path' implementation."
      end

      def lookup_version
        raise McastToolException.new, self.class.to_s + ": Missing 'lookup_version' implementation."
      end

      def check_version
        return false if version.nil?
        return true  if @required_min_version.nil? && @required_max_version.nil?
        ver = Gem::Version.new(version)
        unless @required_min_version.nil?
          min = Gem::Version.new(@required_min_version)
          unless min <= ver
            log_error(self.class.to_s + ": minimum version #{@required_min_version} requirement failed for version #{version}")
            return false
          end
        end
        unless @required_max_version.nil?
          max = Gem::Version.new(@required_max_version)
          log_crit_and_exit(self.class.to_s + ": invalid requirement version maximum #{@required_max_version} < minimum #{@required_min_version}", -1) unless @required_min_version.nil? || min <= max
          unless ver <= max
            log_error(self.class.to_s + ": maximum version #{@required_max_version} requirement failed for version #{version}")
            return false
          end
        end
        log_notice(self.class.to_s + ": passed version check")
        return true
      end

      def valid?
        return (path.nil? || !check_version) ? nil : self
      end

      def path
        log_crit_and_exit("failed to get command for tool, due to unsatisfied dependencies",ERR_TOOL_FAILURE) unless valid?
        log_notice("running: #{path} #{arguments.join(' ')}")
        path.to_s.shellescape
      end

      def run(arguments)
        log_crit_and_exit("failed to run tool with arguments, due to unsatisfied dependencies",ERR_TOOL_FAILURE) unless valid?
        log_notice("running: #{path} #{arguments.join(' ')}")
        do_script(path.to_s, arguments)
      end
    end
  end
end
