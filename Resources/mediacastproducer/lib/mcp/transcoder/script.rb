#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/transcoder/base'
require 'mcp/contrib_cfpropertylist'
require 'mcp/template'
require 'shellwords'

module MediacastProducer
  module Transcoder

    class Script < Base
      include MediacastProducer::Transcoder::ToolWithIOScript
      def self.setup
        true
      end
      def initialize()
        @more_options = []
        @more_options_usage = ""
      end
      def more_options
        @more_options
      end
      def more_options_usage
        @more_options_usage
      end
      def script(arguments)
        
        log_notice('script: ' + @script.to_s)
        
        path = script_for_transcoder(@script)
        log_notice('path: ' + path.to_s)
        
        plist = CFPropertyList::List.new.load(path)
#        puts plist.to_xml
        config = CFPropertyList.native_types(plist)
        @more_options_usage = config['usage']
        print_subcommand_usage(name) if arguments.nil? || arguments.empty?
        data = {}
        opts = {}
        getopt_args = []
        plural_options = []
        config['options'].collect do |option,opttype|
          if option[-1..-1] == "*"
            option = option[0..-2] 
            plural_option = option + "s"
            plural_options << plural_option
          end
          getopt_args << ["--#{option}", GetoptLong::OPTIONAL_ARGUMENT]
          opts[option.to_sym] = opttype
        end
        subcommand_getopt = GetoptLong.new(*getopt_args)
        subcommand_getopt.each do |option, value|
          case option
            when /--(.*)/
              name = $1
              plural_name = name + "s"
              if plural_options.include?(plural_name)
                $subcommand_options[plural_name.to_sym] ||= []
                $subcommand_options[plural_name.to_sym] << value
              else
                $subcommand_options[name.to_sym] = value
              end
          end
        end
        @more_options = opts
#        $subcommand_options.each do |k,v|
#          puts "#{k}: #{v}"
#        end
        opts.each do |option,opttype|
          require_option(option)
          puts "#{option}: #{opttype}"
          
          val = $subcommand_options[option]
          begin
            if opttype.downcase == "integer"
              val = Integer(val)
            elsif opttype.downcase == "real"
              val = Float(val)
            end
          rescue ArgumentError => e
            log_crit_and_exit("argument '--#{option}' got an #{e.message}", ERR_INVALID_ARG_TYPE)
          end
          data[option.to_s] = val.to_s.shellescape
        end
        commands = []
        config['commands'].split(',').each do |c|
#          puts c
          commands << c
          data[c.to_s] = c.to_s.shellescape
        end
        data['input'] = @input.to_s.shellescape
        data['output'] = @output.to_s.shellescape
        config['arguments'].collect do |a|
#          puts a
          b = MediacastProducer::Template.substitute(a,data)
#          puts b
          arguments << b
        end
        log_notice("arguments: #{arguments.join(' ')}")
        unless true
          log_crit_and_exit("Failed to transcode '#{@input}' to '#{@output}' with script '#{@script}'", -1) 
        end
      end
    end

  end
end