#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'actions/base'
require 'mcp/actions'
require 'mcp/common/mcast_exception'

module MediacastProducer
  module Actions
    module Base
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
    end

    module ToolWithIOPreset
      include MediacastProducer::Actions::Base
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
        "           [--path]     print path to executable path and exit\n" +
        "           [--version]  print executable path version and exit\n"
      end

      def run(arguments)

        require_plural_option(:inputs, 1, 1) if options.include?("input*")
        @input = $subcommand_options[:inputs][0]

        require_option(:output) if options.include?("output")
        @output = $subcommand_options[:output]
        #require_option(:preset)

        @preset = $subcommand_options[:preset]

        if options.include?("input*")
          check_input_and_output_paths_are_not_equal(@input, @output) if options.include?("output")
          check_input_file_exclude_dir(@input)
        end
        check_output_file_exclude_dir(@output) if options.include?("output")

        encode(arguments)
      end

      def encode(arguments)
        raise McastToolException.new, self.to_s + ": Missing 'encode' implementation."
      end
    end

    module ToolWithIOTemplate
      include MediacastProducer::Actions::Base
      def description
        "transcodes the INPUT file to the OUTPUT file with the specified tool TEMPLATE"
      end

      def options
        ["input*", "output", "template", "verbose"] + more_options
      end

      def options_usage
        "usage:  #{name} --prb=PRB --input=INPUT --output=OUTPUT --template=TEMPLATE\n" +
        "       [--verbose]  run with verbose output"
        "#{more_options_usage}\n" +
        "the available templates are:\n#{available_templates}\n"
      end

      def run(arguments)

        require_plural_option(:inputs, 1, 1) if options.include?("input*")
        @input = $subcommand_options[:inputs][0]

        require_option(:output) if options.include?("output")
        @output = $subcommand_options[:output]

        require_option(:template) if options.include?("template")
        @template = $subcommand_options[:template]

        if options.include?("input*")
          check_input_and_output_paths_are_not_equal(@input, @output) if options.include?("output")
          check_input_file_exclude_dir(@input)
        end
        check_output_file_exclude_dir(@output) if options.include?("output")

        template(arguments)
      end

      def template(arguments)
        raise McastToolException.new, self.to_s + ": Missing 'template' implementation."
      end
    end

    module ToolWithArguments
      include MediacastProducer::Actions::Base
      def command
        return @command unless @command.nil?
        @command = tool_with_name(name)
      end

      def description
        "execute #{name} with passed arguments"
      end

      def options_usage
        "usage: #{name} --prb=PRB -- [--arguments passed to #{name}]\n" +
        "         [--path]     print #{name} executable path and exit\n" +
        "         [--version]  print #{name} executable version and exit\n" +
        "#{more_options_usage}"# +
        # "the available presets are:\n#{available_presets(name)}\n"
      end

      def options
        ["path", "version"] + more_options
      end

      def run(arguments)

        begin
          if options.include?("path") && !$subcommand_options[:path].nil?
            puts command.tool_path
            return
          end
          if options.include?("version") && !$subcommand_options[:version].nil?
            puts command.tool_version
            return
          end
        rescue McastToolException => e
          log_crit_and_exit(e.message, e.return_code.to_i)
        end

        log_crit_and_exit("failed to setup tools: #{name}", ERR_TOOL_FAILURE) unless command.valid?

        if arguments.nil? || arguments.empty?
          log_error "No command or arguments were specified."
        end
        command.run(*arguments)
      end
    end
  end
end
