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
require 'mcp/plist/preset'
require 'mcp/misc/template_string'
require 'shellwords'

module MediacastProducer
  module Transcoder
    class Script < Base
      include MediacastProducer::Transcoder::ToolWithIOScript
      def setup
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
        arguments = ARGV
        data = {}
        tpl.sanatize_options($subcommand_options).collect do |option, value|
          require_option(option)
          data[option] = value.to_s.shellescape
        end
        tpl.commands.each do |c|
          data[c] = c.to_s.shellescape
        end
        data['input'] = @input.to_s.shellescape
        data['output'] = @output.to_s.shellescape
        tpl.arguments.each do |arg|
          arguments << MediacastProducer::Misc::TemplateString.substitute(arg,data)
        end
        log_notice("arguments: #{arguments.join(' ')}")
        unless true
          log_crit_and_exit("Failed to transcode '#{@input}' to '#{@output}' with template '#{@template}'", -1)
        end
      end
    end

  end
end