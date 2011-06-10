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

module MediacastProducer
  module Transcoder

    class Base
      
      def self.inherited(subclass)
        MediacastProducer::Transcoder.add_action_class(subclass)
      end
      
      def setup
        raise McastToolException.new, self.to_s + ": Missing 'setup' implementation."
      end
      
      def command
        raise McastToolException.new, self.to_s + ": Missing 'command' implementation."
      end
      
      def name
        self.class.name.split("::").last.downcase
      end
      
      def description
        "..."
      end
      
      def usage
        "#{name}: #{description}\n\n" +
        "#{options_usage}"
      end
      
      def options
        [] + more_options
      end
      
      def options_usage
        ""
      end
      
      def more_options
        []
      end
      
      def more_options_usage
        ""
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

    module ToolWithIOPreset
      def description
        "transcodes the input file to the output file with the specified preset"
      end
      
      def options
        ["input*", "output", "preset"] + more_options
      end
      
      def options_usage
        "usage:  #{name} --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET\n" +
        "#{more_options_usage}\n" +
        "the available presets are:\n#{available_presets(name)}\n"
      end
      
      def more_options
        ["path", "version"]
      end
      
      def more_options_usage
        "           [--path]   print path to executable path and exit\n" +
        "           [--version]  print executable path version and exit\n"
      end
      
      def run(arguments)
        
        log_crit_and_exit("Failed to setup tools for transcoder: #{name}", -1) unless setup
        
        if options.include?("path") && !$subcommand_options[:path].nil?
          puts command.path
          return
        end
        
        if options.include?("version") && !$subcommand_options[:version].nil?
          puts command.version
          return
        end
        
        require_plural_option(:inputs, 1, 1) if options.include?("input*")
        @input = $subcommand_options[:inputs][0]
        
        require_option(:output) if options.include?("output")
        @output = $subcommand_options[:output]
        #require_option(:preset)
        
        @preset = $subcommand_options[:preset]
        
        if options.include?("input*")
          check_input_and_output_paths_are_not_equal(@input, @output) if options.include?("output")
          check_input_file(@input)
        end
        check_output_file(@output) if options.include?("output")
        
        encode(arguments)
      end
      
      def encode(arguments)
        raise McastToolException.new, self.to_s + ": Missing 'encode' implementation."
      end
    end
    
    module ToolWithIOScript
      def description
        "transcodes the INPUT file to the OUTPUT file with the specified SCRIPT"
      end
      
      def options
        ["input*", "output", "script"] + more_options
      end
      
      def options_usage
        "usage:  #{name} --prb=PRB --input=INPUT --output=OUTPUT --script=SCRIPT\n" +
        "#{more_options_usage}\n" +
        "the available scripts are:\n#{available_scripts}\n"
      end
      
      def run(arguments)
        
        log_crit_and_exit("Failed to setup tools for transcoder: #{name}", -1) unless setup
        
        require_plural_option(:inputs, 1, 1) if options.include?("input*")
        @input = $subcommand_options[:inputs][0]
        
        require_option(:output) if options.include?("output")
        @output = $subcommand_options[:output]
        
        require_option(:script) if options.include?("script")
        @script = $subcommand_options[:script]
        
        if options.include?("input*")
          check_input_and_output_paths_are_not_equal(@input, @output) if options.include?("output")
          check_input_file(@input)
        end
        check_output_file(@output) if options.include?("output")
        
        script(arguments)
      end
      
      def script(arguments)
        raise McastToolException.new, self.to_s + ": Missing 'script' implementation."
      end
    end
    
    module ToolWithArguments
      def description
        "execute #{name} with passed arguments"
      end
      def options_usage
        "usage: #{name} --prb=PRB -- [--arguments passed to #{name}]\n" +
        "         [--path]   print path to executable path and exit\n" +
        "         [--version]  print executable path version and exit\n" +
        "#{more_options_usage}"# +
        # "the available presets are:\n#{available_presets(name)}\n"
      end
      def options
        ["path", "version"] + more_options
      end
      def run(arguments)
        
        log_crit_and_exit("Failed to setup tools for transcoder: #{name}", -1) unless setup
        
        if options.include?("path") && !$subcommand_options[:path].nil?
          puts command.path
          return
        end
        
        if options.include?("version") && !$subcommand_options[:version].nil?
          puts command.version
          return
        end
        
        if arguments.nil? || arguments.empty?
          log_error "No command or arguments were specified."
        end
        command.run(arguments)
      end
    end
  end
end
