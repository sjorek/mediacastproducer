##  
##  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
##
##  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
##  and is subject to the terms and conditions of the Apple Software License Agreement 
##  accompanying the package this file is a part of.  You may not port this file to 
##  another platform without Apple's written consent.
##
##
#require 'mcp/transcoder/vlc'
#
#module MediacastProducer
#  module Transcoder
#    class VLC2Ogg < VLC
#      include MediacastProducer::Transcoder::CommandWithIOPreset
#      def more_options
#        super + 
#        ["video_quality", "video_bitrate", "video_width", "video_height",
#         "audio_quality", "audio_bitrate", "audio_channels", "audio_samplerate"]
#      end
#      
#      def more_options_usage
#        super + 
#        "preset usage ...\n"
#      end
#      
#      def encode(arguments, input, output, preset=nil)
#        
#        require_option(:preset)
#        log_notice('preset: ' + preset.to_s)
#        
#        settings = preset_for_transcoder(name, preset)
#        log_notice('settings: ' + settings.to_s)
#        
#        unless true
#          log_crit_and_exit("Failed to transcode '#{input}' to '#{output}' with preset '#{preset}'", -1) 
#        end
#      end
#      
#      def preset_defaults
#        @video_quality    = 5
#        @video_bitrate    = 700
#        @video_width      = 320
#        @video_height     = 240
#        
#        @audio_quality    = 1
#        @audio_bitrate    = 64
#        @audio_channels   = 2
#        @audio_samplerate = 44100
#      end
#      
#      def validate_preset
#        ![command.binary, @input, @output,
#          @video_quality, @video_bitrate, @video_width, @video_height,
#          @audio_quality, @audio_bitrate, @audio_channels, @audio_samplerate].include?(nil)
#      end
#      
#      def compile_preset
#        [command.binary,
#         #"-vvvv",
#         "-I", "dummy", 
#         "--play-and-exit", @input,
#         "--no-sout-transcode-hurry-up",
#         "--no-ffmpeg-hurry-up",
#         "--sout-transcode-high-priority",
#         "--sout-theora-quality=#{@video_quality}",
#         "--sout-vorbis-quality=#{@audio_quality}",
#         "--sout=\"#transcode{" +
#            "venc=theora,vcodec=theo,vb=#{@video_bitrate}," +
#            "scale=1,deinterlace=0," +
#            "croptop=0,cropbottom=0,cropleft=0,cropright=0," +
#            "vfilter=canvas{width=#{@video_width},height=#{@video_height}}," +
#            "acodec=vorb,ab=#{@audio_bitrate}," +
#            "channels=#{@audio_channels},samplerate=#{@audio_samplerate}," +
#            "afilter=ugly_resampler}" +
#            ":standard{access=file,mux=ogg,dst='#{@output}'}\""]
#      end
#      
#      def run_preset(arguments)
#  #      if File.exist?(preset) && !File.directory?(preset)
#  #        settings = preset
#  #      else
#  #        require_encoder(preset)
#  #        settings = settings_for_encoder(preset)
#  #      end
#  #      log_notice('preset: ' + preset.to_s)
#  #      log_notice('settings: ' + settings.to_s)
#  #      log_crit_and_exit("Failed to transcode '#{input}' with '#{preset}'", -1) unless McastQT.encode(input, output, settings)
#          c = compile_preset.join(" ")
#          log_notice("\n" + c)
##          `#{c}`
#      end
#    end
#  end
#end