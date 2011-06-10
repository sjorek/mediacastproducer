#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/commands/base'

FFMPEG2THEORA_BIN = "ffmpeg2theora"
FFMPEG2THEORA_WHICH = "/usr/bin/which #{FFMPEG2THEORA_BIN}"
FFMPEG2THEORA_MIN_VERSION = "0.27"
FFMPEG2THEORA_MAX_VERSION = nil

module MediacastProducer
  module Commands

    class FFMpeg2Theora < Base
      @require_min_version = FFMPEG2THEORA_MIN_VERSION
      @require_max_version = FFMPEG2THEORA_MAX_VERSION
      def self.lookup_binary
#        log_notice(self.to_s + ": searching ffmpeg2theora: #{FFMPEG2THEORA_WHICH}")
        path = `#{FFMPEG2THEORA_WHICH}`.chop
        return nil if path == "" || !File.executable?(path)
        log_notice(self.to_s + ": found ffmpeg2theora: " + path.to_s)
        path
      end
      def self.lookup_version
        `#{self.binary} | head -n 1 | cut -f2 -d' '`.chop
      end
    end

  end
end