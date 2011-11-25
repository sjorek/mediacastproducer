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
require 'mcp/qt/qt'

module PodcastProducer
  module Actions
    class Quicktime < Base
      include MediacastProducer::Actions::Base
      def description
        "transcodes the input file to the output file with the specified preset"
      end

      def options
        ["input*", "output", "preset"]
      end

      def options_usage
        "usage:  #{name} --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET\n\n" +
        "the available presets are:\n#{available_mediaencoders}\n"
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

        require_option(:preset)
        log_notice('preset: ' + @preset.to_s)

        settings = preset_for_transcoder(name, @preset)
        log_notice('settings: ' + settings.to_s)

        unless McastQT.encode(@input, @output, settings)
          log_crit_and_exit("failed to transcode '#{@input}' to '#{@output}' with preset '#{@preset}'", -1)
        end
      end
    end

  end
end