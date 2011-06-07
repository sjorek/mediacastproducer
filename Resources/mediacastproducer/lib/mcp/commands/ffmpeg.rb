#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/tools/command'

FFMPEG_BIN = "ffmpeg"
FFMPEG_WHICH = "/usr/bin/which #{FFMPEG_BIN}"
FFMPEG_MIN_VERSION = "0.6.3"
FFMPEG_MAX_VERSION = nil

module MediacastProducer
  module Tools

    class FFMpeg < Command
      @require_min_version = FFMPEG_MIN_VERSION
      @require_max_version = FFMPEG_MAX_VERSION
      def self.lookup_binary
#        log_notice(self.to_s + ": searching ffmpeg: #{FFMPEG_WHICH}")
        path = `#{FFMPEG_WHICH}`.chop
        return nil if path == "" || !File.executable?(path)
        log_notice(self.to_s + ": found ffmpeg: " + path.to_s)
        path
      end
      def self.lookup_version
        `#{self.binary} -version 2>/dev/null | head -n 1 | cut -f2 -d' '`.chop
      end
    end

  end
end