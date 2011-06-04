#
#  Copyright (c) 2006-2008 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/transcoder/base'
require 'mcp/qt/qt'


module MediacastProducer
  module Transcoder
    class Pcast < Base
      def run(input, output, preset)
        check_input_file(input)
        check_output_file(output)
        if File.exist?(preset) && !File.directory?(preset)
          settings = preset
        else
          require_encoder(preset)
          settings = settings_for_encoder(preset)
        end
        log_notice('preset: ' + preset.to_s)
        log_notice('settings: ' + settings.to_s)
        log_crit_and_exit("Failed to transcode '#{input}' with '#{preset}'", -1) unless McastQT.encode(input, output, settings)
      end
    end
  end
end