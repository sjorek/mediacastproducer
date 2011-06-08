#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/transcoder/vlc/dummy'

module MediacastProducer
  module Preset
    module VLC
      module Dummy2
        def preset_defaults
          @video_quality    = 5
          @video_bitrate    = 700
          @video_width      = 320
          @video_height     = 240
          
          @audio_quality    = 5
          @audio_bitrate    = 64
          @audio_channels   = 2
          @audio_samplerate = 44100
        end
        
        def preset_usage
          "preset usage 2 ...\n"
        end
      end
    end
  end
  module Transcoder
    class VLC
      include MediacastProducer::Preset::VLC::Dummy2
    end
  end
end