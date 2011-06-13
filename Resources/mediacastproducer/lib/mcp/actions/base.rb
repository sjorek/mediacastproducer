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
        "#{more_options_usage}"
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
