#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/transcoder/base'
require 'mcp/qt/qt'

FFMPEG_BIN = "ffmpeg"
FFMPEG_WHICH = "/usr/bin/which #{FFMPEG_BIN}"

module MediacastProducer
  module Transcoder
    class FFMpeg < Base
      @@ffmpeg = nil
      def self.ffmpeg
        @@ffmpeg
      end
      def self.lookup_tools
        log_notice("searching ffmpeg: #{FFMPEG_WHICH}")
        ffmpeg = `#{FFMPEG_WHICH}`.chop
        return false if ffmpeg == "" || !File.executable?(ffmpeg)
        log_notice("found ffmpeg: " + ffmpeg.to_s)
        @@ffmpeg = ffmpeg
      end
      def usage
        "ffmpeg: transcodes the input file to the output file with the specified preset\n\n" +
        "usage:  ffmpeg --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET\n\n" +
        "the available presets are:\n#{available_transcoders('ffmpeg')}\n"
      end
      def options
        ["input*", "output", "preset"]
      end
      def run(arguments)
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