#
#  Copyright (c) 2006-2009 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'actions/base'
require 'mediacastproducer/qt/qt'

module PodcastProducer
  module Actions

    class Faststart < Base
      def usage
        "faststart: optimize Quicktime or Mp4-alike for streaming\n\n" +
        "usage: faststart --prb=PRB --input=INPUT\n"+
        "                [--output=OUTPUT]  write to OUTPUT, otherwise work in place on INPUT\n" +
        "                [--streamable]     test and exits accordingly with 0 or 1; e.g.:\n" +
        "                                   ... && echo true || echo false\n"
      end
      def options
        ["input*", "streamable", "output"]
      end
      def run(arguments)
        require_plural_option(:inputs, 1, 1)
        
        input = $subcommand_options[:inputs][0]
        output = $subcommand_options[:output]
        is_streamable = McastQT.is_streamable?(input)
        if is_streamable || $subcommand_options[:streamable]
          log_notice "is already streamable: " + is_streamable.to_s
          exit(is_streamable ? 0 : 1)
          return
        end
        faststart = File.join(MCP_BIN_DIR,"mp4-faststart")
        if output
          system(faststart, input, output)
        else
          system(faststart, input)
        end
      end
    end
    
  end
end
