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

    class Base
      
      def initialize()
        preset_for_transcoder(name)
      end
      
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
      
      def preset_usage
        ""
      end
      
      def preset_options
        []
      end
      
      def require_preset
      end
      
      def transcoder_options
        options + preset_options
      end
      
      def run(arguments)
        
        unless $subcommand_options[:binary].nil?
          puts command.binary
          return
        end
        
        unless $subcommand_options[:version].nil?
          puts command.version
          return
        end
        
        require_plural_option(:inputs, 1, 1)
        require_option(:output)
        require_option(:preset)
        
        @input = $subcommand_options[:inputs][0]
        @output = $subcommand_options[:output]
        @preset = $subcommand_options[:preset]
        
        if $transcoder_engine.nil? && $transcoder_preset.nil?
          $transcoder_engine = name
          $transcoder_preset = @preset
          log_notice("running again with preset #{@preset}")
          return self.class.new.run(arguments)
        end
        
        check_input_and_output_paths_are_not_equal(@input, @output)
        check_input_file(@input)
        check_output_file(@output)
        
        preset_defaults
        require_preset
        run_preset(arguments)
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
