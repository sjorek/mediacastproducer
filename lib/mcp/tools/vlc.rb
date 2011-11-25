#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/tools/base'

MCP_VLC_SEARCH_PATH = "/Applications"
MCP_VLC_BIN_NAME = "VLC"
MCP_VLC_BIN_PATH = "Contents/MacOS/#{MCP_VLC_BIN_NAME}"
MCP_VLC_LOCATE = "locate \"#{MCP_VLC_BIN_PATH}\" | grep -E \"^#{MCP_VLC_SEARCH_PATH}.*#{MCP_VLC_BIN_PATH}$\""
MCP_VLC_MDFIND = "mdfind -onlyin \"#{MCP_VLC_SEARCH_PATH}\" \"#{MCP_VLC_BIN_NAME}.app\""
MCP_VLC_FIND = "find \"#{MCP_VLC_SEARCH_PATH}\" -type f -name \"#{MCP_VLC_BIN_NAME}\" | grep -E \"#{MCP_VLC_BIN_PATH}$\""
MCP_VLC_MIN_VERSION = "1.1.10"
MCP_VLC_MAX_VERSION = nil

module MediacastProducer
  module Tools
    class VLC < CommandBase
      def initialize(path_to_tool=nil)
        super(path_to_tool, MCP_VLC_MIN_VERSION, MCP_VLC_MAX_VERSION)
      end

      def lookup_path
        path = `#{MCP_VLC_LOCATE} | head -n 1`
        if path == ""
          path = `#{MCP_VLC_MDFIND} | head -n 1`.chomp!
          unless path == "" || !File.directory?(path)
            path = File.join(path, MCP_VLC_BIN_PATH)
          else
            path = `#{MCP_VLC_FIND} | head -n 1`
          end
        end
        path
      end

      def lookup_version
        `#{tool_path} --intf dummy --version | head -n 1 | cut -f2 -d' '`
      end

      def command_line(verbose=false)
        [tool_path, verbose ? "-vvvv" : "-q", "--ignore-config",
         "--intf", "dummy", "--extraintf", "rc",
         "--lua-config", "rc={host='localhost:4212'}", "--play-and-exit",
         verbose ? "--no-sout-x264-quiet" : "--sout-x264-quiet"]
      end

      def update_status(loop = true)
        position = nil
        duration = nil
        tries = 3
        sleep(1) if loop
        begin
          position=`echo get_time | nc -i 1 localhost 4212 | grep -E "^> [0-9]+" | sed -e "s|^> ||g"`.chomp
          duration=`echo get_length | nc -i 1 localhost 4212 | grep -E "^> [0-9]+" | sed -e "s|^> ||g"`.chomp unless duration
          unless ( position == "" || duration == "" )
            percent = position.to_f * 100.0 / duration.to_f
            log_notice("processed #{position} seconds of #{duration} seconds => #{percent} %")
            yield percent if block_given?
          else
            yield 0.0 if block_given? && !loop
          end
          if tries>0 && loop
            sleep(1) if position == "" || duration == ""
            tries -= 1
          end
        end while loop && ( tries>0 || ! ( position == "" || duration == "" ) )
        log_notice("processed #{duration} seconds of #{duration} seconds => 100.0 %") unless duration == "" && !loop
      end
    end

  end
end