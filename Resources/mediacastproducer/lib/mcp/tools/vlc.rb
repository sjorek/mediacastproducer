#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/tools/base'

VLC_SEARCH_PATH = "/Applications"
VLC_BIN_NAME = "VLC"
VLC_BIN_PATH = "Contents/MacOS/#{VLC_BIN_NAME}"
VLC_LOCATE = "locate \"#{VLC_BIN_PATH}\" | grep -E \"^#{VLC_SEARCH_PATH}.*#{VLC_BIN_PATH}$\""
VLC_MDFIND = "mdfind -onlyin \"#{VLC_SEARCH_PATH}\" \"#{VLC_BIN_NAME}.app\""
VLC_FIND = "find \"#{VLC_SEARCH_PATH}\" -type f -name \"#{VLC_BIN_NAME}\" | grep -E \"#{VLC_BIN_PATH}$\""
VLC_MIN_VERSION = "1.1.9"
VLC_MAX_VERSION = nil

module MediacastProducer
  module Tools
    class VLC < Base
      def initialize(path_to_tool=nil)
        super(path_to_tool, VLC_MIN_VERSION, VLC_MAX_VERSION)
      end

      def lookup_path
        #        log_notice("searching VLC.app: #{VLC_LOCATE}")
        path = `#{VLC_LOCATE} | head -n 1`.chop
        if path == ""
          #          log_notice("searching VLC.app: #{VLC_MDFIND}")
          path = `#{VLC_MDFIND} | head -n 1`.chop
          unless path == "" || !File.directory?(path)
            path = File.join(path, VLC_BIN_PATH)
          else
            #            log_notice("searching VLC.app: #{VLC_FIND}")
            path = `#{VLC_FIND} | head -n 1`.chop
          end
        end
        return nil if path == "" || !File.executable?(path)
        log_notice("found #{name}: " + path.to_s)
        path
      end

      def lookup_version
        `#{tool_path} --intf dummy --version | head -n 1 | cut -f2 -d' '`.chop
      end

    end

  end
end