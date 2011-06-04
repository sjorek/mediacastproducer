#
#  Copyright (c) 2006-2008 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'actions/base'
require 'mcp/transcoder'

MediacastProducer::Transcoders.load_transcoders
$engines = PodcastProducer::Transcoders.action_instances

module PodcastProducer
  module Actions

    class Transcode < Base
      def usage
        "transcode: transforms the input file to the output file with the specified preset\n\n" +
        "usage: transcode --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET\n\n" +
        "the available presets are:\n#{available_transcoders}\n\n"
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
        if File.exist?(preset)
          engine = "pcast" if File.extname(preset) == ".plist"
          engine = File.basename(File.dirname(Pathname.new(__FILE__).realpath)) if File.extname(preset) == ".rb"
        else
          preset =~ %r{(.*)/(.*)}
          engine, encoder = $1, $2
        end
        
#        check_input_file(input)
#        check_output_file(output)
#        
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
