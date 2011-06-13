#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'shellwords'
require 'mcp/transcoder'
require 'mcp/actions/base'
require 'mcp/plist/script_template'
require 'mcp/common/templates'

module PodcastProducer
  module Actions
    class ToolScript < Base
      include MediacastProducer::Actions::Base
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
        "                     leave empty to get help\n" +
        "#{more_options_usage}\n" +
        "the available scripts are:\n#{available_scripts}\n"
      end

      def more_options
        @more_options
      end

      def more_options_usage
        @more_options_usage
      end

      def run(arguments)

        require_plural_option(:inputs, 1, 1) if options.include?("input*")
        @input = $subcommand_options[:inputs][0]

        require_option(:output) if options.include?("output")
        @output = $subcommand_options[:output]

        require_option(:script) if options.include?("script")
        @script = $subcommand_options[:script]

        if options.include?("input*")
          check_input_and_output_paths_are_not_equal(@input, @output) if options.include?("output")
          check_input_file_exclude_dir(@input)
        end
        check_output_file_exclude_dir(@output) if options.include?("output")

        log_notice('script: ' + @script.to_s)

        path = script_for_transcoder(@script)
        log_notice('path: ' + path.to_s)

        script = MediacastProducer::Plist::ScriptTemplate.new(path)
        @more_options_usage = script.usage

        print_subcommand_usage(name) if arguments.nil? || arguments.empty?

        getopt_args = []
        plural_options = []
        script.options.each do |option,opttype|
#          log_notice("#{option}: #{opttype}")
          if option[-1..-1] == "*"
            option = option[0..-2]
            plural_option = option + "s"
            plural_options << plural_option
          end
          getopt_args << ["--#{option}", GetoptLong::OPTIONAL_ARGUMENT]
          @more_options << option
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
        data = {}
        script.sanatize_options { |option, value|
#          log_notice("#{option}: #{value}")
          data[option] = value.to_s.shellescape
        }
        data['input'] = @input.to_s.shellescape
        data['output'] = @output.to_s.shellescape
        tools = []
        script.commands.each do |c|
          tool = tool_with_name(c)
          log_crit_and_exit("tool #{c} not found",ERR_TOOL_FAILURE) if tool.nil?
          log_crit_and_exit("failed to setup tools: #{c}", ERR_TOOL_FAILURE) unless tool.valid?
          data[c] = tool.command_line(!$subcommand_options[:verbose].nil?)
          tools << tool
        end
        begin
          arguments = MediacastProducer::Common::TemplateArray.substitute(script.arguments + arguments, data)
        rescue McastTemplateException => e
          log_crit_and_exit(e.message,e.return_code.to_i)
        end
        log_notice(arguments.join(' '))
        unless (pid = fork_exec_and_return_pid(*arguments))
          log_crit_and_exit("failed to transcode '#{@input}' to '#{@output}' with script '#{@script}'", -1)
        end
        begin
          puts "<xgrid>\n{control = statusUpdate; percentDone = 0.0; }\n</xgrid>"
          tools.each do |tool|
            next unless tool.respond_to?(:update_status)
            tool.update_status(pid) { |percent|
              puts "<xgrid>\n{control = statusUpdate; percentDone = #{percent}; }\n</xgrid>"
            }
          end
          pid, status = Process.waitpid2(pid)
          puts "<xgrid>\n{control = statusUpdate; percentDone = 100.0; }\n</xgrid>"
        rescue SystemExit, Interrupt
          Process.kill('HUP', pid)
          pid, status = Process.waitpid2(pid)
        end
        log_notice("pid: #{pid} exit status: #{status.exitstatus}")
        log_crit_and_exit("failed to transcode '#{@input}' to '#{@output}' with script '#{@script}'",status.exitstatus) unless status.exitstatus == 0
      end
    end

  end
end