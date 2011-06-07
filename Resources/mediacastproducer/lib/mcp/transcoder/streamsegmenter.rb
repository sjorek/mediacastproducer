#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/transcoder/base'
require 'mcp/tools/streamsegmenter'

module MediacastProducer
  module Transcoder

    class StreamSegmenter < Base
      @@segmenter = nil
      def self.load_tools
        @@segmenter = MediacastProducer::Commands::StreamSegmenter.load
      end
      def usage
        "streamsegmenter: transcodes the input file to the output file with the specified preset\n\n" +
        "usage:  streamsegmenter --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET\n" +
        "                       [--binary]   print path to executable binary and exit\n" +
        "                       [--version]  print executable binary version and exit\n\n" +
        "the available presets are:\n#{available_transcoders('streamsegmenter')}\n"
      end
      def options
        ["input*", "output", "preset", "binary"]
      end
      def run(arguments)
        
        unless $subcommand_options[:binary].nil?
          puts @@segmenter.binary
          return
        end
        
        unless $subcommand_options[:version].nil?
          puts @@segmenter.version
          return
        end
        
        require_plural_option(:inputs, 1, 1)
        require_option(:output)
        require_option(:preset)
        
        preset = $subcommand_options[:preset]
        input = $subcommand_options[:inputs][0]
        output = $subcommand_options[:output]
        
        check_input_file(input)
        check_output_file(output)
#        if File.exist?(preset) && !File.directory?(preset)
#          settings = preset
#        else
#          require_encoder(preset)
#          settings = settings_for_encoder(preset)
#        end
#        log_notice('preset: ' + preset.to_s)
#        log_notice('settings: ' + settings.to_s)
#        log_crit_and_exit("Failed to transcode '#{input}' with '#{preset}'", -1) unless McastQT.encode(input, output, settings)
      end
    end

  end
end