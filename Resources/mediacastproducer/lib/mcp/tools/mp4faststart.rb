#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/tools/base'

MP4_FASTSTART = File.join(MCP_LIBEXEC,"mp4-faststart.py")

module MediacastProducer
  module Tools
    class MP4Faststart < Base
      def initialize(path_to_tool=nil)
        super(path_to_tool)
      end

      def lookup_path
        path = MP4_FASTSTART
        return nil if path == "" || !File.executable?(path)
        log_notice("found #{name}: " + path.to_s)
        path
      end

      def lookup_version
      end
    end

  end
end