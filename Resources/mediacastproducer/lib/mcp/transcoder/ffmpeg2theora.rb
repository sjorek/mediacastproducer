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

FFMPEG2THEORA_BIN = "ffmpeg2theora"
FFMPEG2THEORA_WHICH = "/usr/bin/which #{FFMPEG2THEORA_BIN}"

module MediacastProducer
  module Transcoder
    
    class FFMpeg2TheoraTool < Tool
      def self.lookup
        log_notice("searching ffmpeg2theora: #{FFMPEG2THEORA_WHICH}")
        path = `#{FFMPEG2THEORA_WHICH}`.chop
        return nil if path == "" || !File.executable?(path)
        log_notice("found ffmpeg2theora: " + path.to_s)
        path
      end
    end
    
    class FFMpeg2Theora < Base
      @@ffmpeg2theora = nil
      def self.load_tools
        @@ffmpeg2theora = FFMpeg2TheoraTool.load
      end
      def usage
        "ffmpeg2theora: transcodes the input file to the output file with the specified preset\n\n" +
        "usage:  ffmpeg2theora --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET\n" +
        "                     [--binary]  print path to executable binary and exit\n\n" +
        "the available presets are:\n#{available_transcoders('ffmpeg2theora')}\n"
      end
      def options
        ["input*", "output", "preset", "binary"]
      end
      def run(arguments)
        unless $subcommand_options[:binary].nil?
          puts @@ffmpeg2theora.binary
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