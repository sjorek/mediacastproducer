#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/tools/base'

MCP_FFMPEG_BIN = "ffmpeg"
MCP_FFMPEG_WHICH = "/usr/bin/which #{MCP_FFMPEG_BIN}"
MCP_FFMPEG_MIN_VERSION = "0.6.3"
MCP_FFMPEG_MAX_VERSION = nil

module MediacastProducer
  module Tools
    class FFMpeg < CommandBase
      def initialize(path_to_tool=nil)
        super(path_to_tool, MCP_FFMPEG_MIN_VERSION, MCP_FFMPEG_MAX_VERSION)
      end

      def lookup_path
        `#{MCP_FFMPEG_WHICH}`
      end

      def lookup_version
        `#{tool_path} -version 2>/dev/null | head -n 1 | cut -f2 -d' '`
      end
    end

  end
end