#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/actions/base'

module PodcastProducer
  module Actions
    class MediafileSegmenter < Base
      include MediacastProducer::Actions::ToolWithArguments
    end
  end
end