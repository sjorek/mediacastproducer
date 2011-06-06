#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/transcoder'
require 'mcp/common/mcast_exception'
require 'rubygems'

module MediacastProducer
  module Transcoder
    
    class Tool
      @binary = nil
      @version = nil
      @require_min_version = nil
      @require_max_version = nil
      def self.binary
         return @binary unless @binary.nil?
         @binary = lookup_binary
      end
      def self.version
         return @version unless @version.nil?
         @version = lookup_version
      end
      def self.lookup_binary
        raise McastToolException.new, self.to_s + ": Missing 'lookup_binary' implementation."
      end
      def self.lookup_version
        raise McastToolException.new, self.to_s + ": Missing 'lookup_version' implementation."
      end
      def self.check_version
        return false if self.version.nil?
        return true  if @require_min_version.nil? && @require_max_version.nil?
        ver = Gem::Version.new(self.version)
        unless @require_min_version.nil?
          min = Gem::Version.new(@require_min_version)
          unless min <= ver
            log_error(self.to_s + ": minimum version #{@require_min_version} requirement failed for version #{self.version}")
            return false
          end
        end
        unless @require_max_version.nil?
          max = Gem::Version.new(@require_max_version)
          log_crit_and_exit(self.to_s + ": invalid requirement version maximum #{@require_max_version} < minimum #{@require_min_version}", -1) unless @require_min_version.nil? || min <= max
          unless ver <= max
            log_error(self.to_s + ": maximum version #{@require_max_version} requirement failed for version #{self.version}")
            return false
          end
        end
        log_notice(self.to_s + ": passed version check")
        return true
      end
      def self.load
        return (self.binary.nil? || !self.check_version) ? nil : self
      end
    end
    
    class Base
      
      def self.inherited(subclass)
        MediacastProducer::Transcoder.add_action_class(subclass)
      end
      
      def self.load_tools
        raise McastToolException.new, self.to_s + ": Missing 'load_tools' implementation."
      end
      
      def name
        self.class.name.split("::").last.downcase
      end
      
      def usage
        "usage"
      end
      
      def options
        []
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
