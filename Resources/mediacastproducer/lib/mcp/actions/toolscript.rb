#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'fileutils'
require 'shellwords'
require 'mcp/transcoder'
require 'mcp/actions/base'
require 'mcp/plist/script_template'
require 'mcp/common/templates'

module PodcastProducer
  module Actions
    class ToolScript < Base
      include MediacastProducer::Actions::Base
      include MediacastProducer::Transcoder::Script
      def initialize()
        @more_options = []
        @more_options_usage = ""
      end

      def description
        "transcodes the INPUT file to the OUTPUT file with the specified tool SCRIPT"
      end

      def options
        ["input*", "output", "script", "verbose"] + more_options
      end

      def options_usage
        "usage:  #{name} --prb=PRB --input=INPUT --output=OUTPUT --script=SCRIPT\n" +
        "        [--verbose]  run with verbose output\n" +
        "        [-- [...]]   additional options depending on the script choosen,\n" +
        "                     leave empty to get help\n"
      end

      def more_options
        @more_options
      end

      def more_options_usage
        "#{@more_options_usage}\n" +
        "the available scripts are:\n#{available_scripts}\n"
      end

      def script
        @script
      end

      def input
        @input
      end

      def output
        @output
      end

      def run(arguments)

        require_option(:script) if options.include?("script")
        @script_name = $subcommand_options[:script]

        log_notice('script name: ' + @script_name.to_s)

        @script_path = script_for_transcoder(@script_name)
        log_notice('script path: ' + @script_path.to_s)

        @script = MediacastProducer::Plist::ScriptTemplate.new(@script_path)
        @more_options_usage = "\nscript: #{@script_name}\n#{@script.description}\n#{@script.usage}\n"

        print_subcommand_usage(name) if arguments.nil? || arguments.empty?

        if options.include?("input*")
          require_plural_option(:inputs, 1, 1)
          @input = $subcommand_options[:inputs][0]
        elsif options.include?("input")
          require_option(:input) if options.include?("input")
          @input = $subcommand_options[:input]
        end

        require_option(:output) if options.include?("output")
        @output = $subcommand_options[:output]

        if options.include?("input*") || options.include?("input")
          check_input_and_output_paths_are_not_equal(@input, @output) if options.include?("output")
          check_input_file_exclude_dir(@input)
        end
        check_output_file_exclude_dir(@output) if options.include?("output")

        getopt_args = []
        plural_options = []
        @script.options.each do |option,opttype|
          #          log_notice("#{option}: #{opttype}")
          if option[-1..-1] == "*"
            option = option[0..-2]
            plural_option = option + "s"
            plural_options << plural_option
          end
          getopt_args << ["--#{option}", GetoptLong::OPTIONAL_ARGUMENT]
          @more_options << option
        end
        begin
          subcommand_getopt = GetoptLong.new(*getopt_args)
          subcommand_getopt.quiet = true
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
        rescue GetoptLong::Error => e
          print_subcommand_usage(name) unless !arguments.nil? && !arguments.empty?
          log_crit_and_exit(e.message,-1)
        end
        log_crit_and_exit("failed to transcode '#{@input}' to '#{@output}' with script '#{@script_name}'", -1) unless run_script(arguments)
      end
    end

  end
end