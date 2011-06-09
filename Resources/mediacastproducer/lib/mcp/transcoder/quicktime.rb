#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/transcoder/base'
require 'mcp/qt/qt'


module MediacastProducer
  module Transcoder

    class Quicktime < Base
      include MediacastProducer::Transcoder::CommandWithIO
      def self.setup
        true
      end
      def more_options
        []
      end
      def more_options_usage
        ""
      end
      def encode(arguments)
        
        require_option(:preset)
        log_notice('preset: ' + @preset.to_s)
        
        settings = preset_for_transcoder(name, @preset)
        log_notice('settings: ' + settings.to_s)
        
        unless McastQT.encode(@input, @output, settings)
          log_crit_and_exit("Failed to transcode '#{@input}' to '#{@output}' with preset '#{@preset}'", -1) 
        end
      end
    end

  end
end