#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/tools/base'

MCP_FFMPEG2THEORA_BIN = "ffmpeg2theora"
MCP_FFMPEG2THEORA_WHICH = "/usr/bin/which #{MCP_FFMPEG2THEORA_BIN}"
MCP_FFMPEG2THEORA_MIN_VERSION = "0.27"
MCP_FFMPEG2THEORA_MAX_VERSION = nil

module MediacastProducer
  module Tools
    class FFMpeg2Theora < CommandBase
      def initialize(path_to_tool=nil)
        super(path_to_tool, MCP_FFMPEG2THEORA_MIN_VERSION, MCP_FFMPEG2THEORA_MAX_VERSION)
      end

      def lookup_path
        `#{MCP_FFMPEG2THEORA_WHICH}`
      end

      def lookup_version
        `#{tool_path} | head -n 1 | cut -f2 -d' '`
      end

      def command_line(verbose=false)
        [tool_path, "--frontend"]
      end
      
      def stdout_status(stdout, verbose=false)
        @running_twopass = nil
        out = []
        last_status = nil
        while line = stdout.gets
          if !out.empty? && line[0] == 123# {
            status = json_to_status(out.join, verbose)
            return if status.nil?
            yield status unless last_status == status || [0.0, 100.0].include?(status)
            last_status = status
            out = []
          end
          out << line.chomp
        end
        return if out.empty?
        status = json_to_status(out.join, verbose)
        yield status unless status.nil? || last_status == status || [0.0, 100.0].include?(status)
        return
      end
      
      def json_to_status(line, verbose=false)
        log_notice(line) if verbose
        if line =~ /^\{"result":\s*"ok"\}$/
          return 100.0
        elsif line =~ /^\{\s*"duration":\s*(\S+)\s*,\s*"position":\s*(\S+)\s*,.*\}$/
          d = Float($1).to_i
          p = Float($2).to_i
          if line =~ /audio_kbps|video_kbps/
            p += d if @running_twopass
          elsif @running_twopass.nil?
            @running_twopass = true
          end
          d *= 2 if @running_twopass
          return p * 100.0 / d
        end
        log_error(line)
        return nil
      end
    end

  end
end