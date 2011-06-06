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

VLC_SEARCH_PATH = "/Applications"
VLC_BIN_NAME = "VLC"
VLC_BIN_PATH = "Contents/MacOS/#{VLC_BIN_NAME}"
VLC_LOCATE = "locate \"#{VLC_BIN_PATH}\" | grep -E \"^#{VLC_SEARCH_PATH}.*#{VLC_BIN_PATH}$\""
VLC_MDFIND = "mdfind -onlyin \"#{VLC_SEARCH_PATH}\" \"#{VLC_BIN_NAME}.app\""
VLC_FIND = "find \"#{VLC_SEARCH_PATH}\" -type f -name \"#{VLC_BIN_NAME}\" | grep -E \"#{VLC_BIN_PATH}$\""

module MediacastProducer
  module Transcoder
    
    class VLCTool < Tool
      def self.lookup
        log_notice("searching VLC.app: #{VLC_LOCATE}")
        path = `#{VLC_LOCATE} | head -n 1`.chop
        if path == ""
          log_notice("searching VLC.app: #{VLC_MDFIND}")
          path = `#{VLC_MDFIND} | head -n 1`.chop
          unless path == "" || !File.directory?(path)
            path = File.join(path, VLC_BIN_PATH) 
          else
            log_notice("searching VLC.app: #{VLC_FIND}")
            path = `#{VLC_FIND} | head -n 1`.chop
          end
        end
        return nil if path == "" || !File.executable?(path)
        log_notice("found VLC.app: " + path.to_s)
        path
      end
    end
    
    class VLC < Base
      @@vlc = nil
      def self.load_tools
        @@vlc = VLCTool.load
      end
      def usage
        "vlc: transcodes the input file to the output file with the specified preset\n\n" +
        "usage:  vlc --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET\n" +
        "           [--binary]  print path to executable binary and exit\n\n" +
        "the available presets are:\n#{available_transcoders('vlc')}\n"
      end
      def options
        ["input*", "output", "preset", "binary"]
      end
      def run(arguments)
        unless $subcommand_options[:binary].nil?
          puts @@vlc.binary
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