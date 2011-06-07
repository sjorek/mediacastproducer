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
      
      include preset_for_transcoder("vlc", $transcoder_preset) if $transcoder_engine == 'vlc' && !$transcoder_preset.nil?
      
      @@vlc = nil
      
      def self.load_tools
        @@vlc = MediacastProducer::Commands::VLC.load
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
      
      def run(arguments)
        
        unless $subcommand_options[:binary].nil?
          puts @@vlc.binary
          return
        end
        
        unless $subcommand_options[:version].nil?
          puts @@vlc.version
          return
        end
        
        require_plural_option(:inputs, 1, 1)
        require_option(:output)
        require_option(:preset)
        
        require_preset_options
        
        @preset = $subcommand_options[:preset]
        @input = $subcommand_options[:inputs][0]
        @output = $subcommand_options[:output]
        
        check_input_file(@input)
        check_output_file(@output)
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