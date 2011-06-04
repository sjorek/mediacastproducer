#
#  Copyright (c) 2006-2008 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'actions/base'
require 'qt/qt'

module PodcastProducer
  module Actions

    class Transcode < Base
      def usage
        "transcode: transforms the input file to the output file with the specified encoder\n\n" +
        "usage: transcode --prb=PRB --input=INPUT --output=OUTPUT --encoder=ENCODER\n\n" +
        "the available encoders are:\n#{available_encoders}"
      end
      def options
        ["input*", "output", "encoder"]
      end
      def run(arguments)
        require_plural_option(:inputs, 1, 1)
        require_option(:output)
        require_option(:encoder)
        
        encoder = $subcommand_options[:encoder]
        input = $subcommand_options[:inputs][0]
        output = $subcommand_options[:output]
       
        check_input_file(input)
        check_output_file(output)
        
        if File.exist?(encoder)
          settings = encoder
        else
          require_encoder(encoder)
          settings = settings_for_encoder(encoder)
        end
        
        log_crit_and_exit("Failed to encode '#{input}' with '#{encoder}'", -1) unless PcastQT.encode(input, output, settings)
      
      end
    end
    
  end
end
