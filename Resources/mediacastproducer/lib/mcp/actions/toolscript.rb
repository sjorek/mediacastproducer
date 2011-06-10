#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/actions/base'
require 'mcp/plist/preset'
require 'mcp/common/template_string'
require 'shellwords'

module PodcastProducer
  module Actions
    class ToolScript < Base
      include MediacastProducer::Actions::ToolWithIOTemplate

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

      def template(arguments)

        log_notice('template: ' + @template.to_s)

        path = template_for_transcoder(@template)
        log_notice('path: ' + path.to_s)

        tpl = MediacastProducer::Plist::Template.new(path)
        @more_options_usage = tpl.usage
        
        print_subcommand_usage(name) if arguments.nil? || arguments.empty?
        
        getopt_args = []
        plural_options = []
        tpl.options.each do |option,opttype|
          log_notice("#{option}: #{opttype}")
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
        tpl.sanatize_options.each do |option, value|
          log_notice("#{option}: #{value}")
          data[option] = value.to_s.shellescape
        end
        tpl.commands.each do |c|
          data[c] = c.to_s.shellescape
        end
        data['input'] = @input.to_s.shellescape
        data['output'] = @output.to_s.shellescape
        begin
          tpl.arguments.each do |arg|
            arguments << MediacastProducer::Common::TemplateString.substitute(arg, data)
          end
        rescue McastTemplateException => e
          log_crit_and_exit(e.message,e.return_code.to_i)
        end
        log_notice(arguments.join(' '))
        unless false
          log_crit_and_exit("Failed to transcode '#{@input}' to '#{@output}' with template '#{@template}'", -1)
        end
      end
    end

  end
end