#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/tools/base'

MEDIASTREAMSEGMENTER_BIN = "mediastreamsegmenter"
MEDIASTREAMSEGMENTER_WHICH = "/usr/bin/which #{MEDIASTREAMSEGMENTER_BIN}"
MEDIASTREAMSEGMENTER_MIN_VERSION = "10.2.10"
MEDIASTREAMSEGMENTER_MAX_VERSION = nil

module MediacastProducer
  module Tools
    class MediastreamSegmenter < CommandBase
      def initialize(path_to_tool=nil)
        super(path_to_tool, MEDIASTREAMSEGMENTER_MIN_VERSION, MEDIASTREAMSEGMENTER_MAX_VERSION)
      end

      def lookup_path
        `#{MEDIASTREAMSEGMENTER_WHICH}`
      end

      def lookup_version
        v = `#{tool_path} -v 2>&1 | cut -f2- -d' '`.chomp!
        v =~ %r{\(([0-9]{2})([0-9]{2})([0-9]{2})\)}
        "#{$1.to_i}.#{$2.to_i}.#{$3.to_i}"
      end
      def command_line(verbose=false)
        return [tool_path] if verbose
        [tool_path, "-q"]
      end
    end

  end
end