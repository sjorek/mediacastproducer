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
        "usage: faststart --prb=PRB --input=INPUT\n" +
        "                [--streamable] exits 0 or 1 e.g.:... && echo true || echo false\n"
      end
      def options
        ["input*", "streamable"]
      end
      def run(arguments)
        require_plural_option(:inputs, 1, 1)
        
        input = $subcommand_options[:inputs][0]
        if $subcommand_options[:streamable]
          is_streamable = McastQT.is_streamable?(input)
          log_notice is_streamable.to_s
          exit(is_streamable ? 0 : 1)
        end
      end
    end
    
  end
end
