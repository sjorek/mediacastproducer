#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/tools/base'

MCP_MEDIACASTSEGMENTER_PATH = File.join(MCP_BIN,"mediacastsegmenter")
MCP_MEDIACASTSEGMENTER_MIN_VERSION = "1.0.3"
MCP_MEDIACASTSEGMENTER_MAX_VERSION = nil

module MediacastProducer
  module Tools
    class MediacastSegmenter < CommandBase
      def initialize(path_to_tool=nil)
        super(path_to_tool, MCP_MEDIACASTSEGMENTER_MIN_VERSION,
                            MCP_MEDIACASTSEGMENTER_MAX_VERSION)
      end

      def lookup_path
        MCP_MEDIACASTSEGMENTER_PATH
      end

      def lookup_version
        `#{tool_path} -v | head -n 1 | cut -f2 -d' '`
      end
    end

  end
end