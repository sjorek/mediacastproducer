#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/transcoder/base'
require 'mcp/tools/streamsegmenter'

module MediacastProducer
  module Transcoder

    class StreamSegmenter < Base
      include MediacastProducer::Transcoder::ToolWithArguments
      @@streamsegmenter = nil
      def self.setup
        @@streamsegmenter = MediacastProducer::Tools::StreamSegmenter.load if @@streamsegmenter.nil?
      end
      def command
        @@streamsegmenter
      end
    end

  end
end