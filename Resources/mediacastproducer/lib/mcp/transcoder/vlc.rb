#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/transcoder/base'
require 'mcp/commands/vlc'

module MediacastProducer
  module Transcoder

    class VLC < Base
      
      @@vlc = nil
      
      def self.load_tools
        @@vlc = MediacastProducer::Commands::VLC.load if @@vlc.nil?
      end
      
      def command
        @@vlc
      end
      
      def usage
        "vlc: transcodes the input file to the output file with the specified preset\n\n" +
        "usage:  vlc --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET\n" +
        "           [--binary]   print path to executable binary and exit\n" +
        "           [--version]  print executable binary version and exit\n" +
        "#{preset_usage}\n" +
        "the available presets are:\n#{available_transcoders('vlc')}\n"
      end
      
      def options
        ["input*", "output", "preset", "binary", "version"]
      end
      
    end
  end
end