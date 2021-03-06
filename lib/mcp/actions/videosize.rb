#
#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2009 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'fileutils'
require 'mcp/actions/base'
require 'mcp/qt/qt'

MCP_VIDEOSIZE_CLEANER = 'mcp_qt_clean_24fps_aac_192kbit_44100' # 'qt_clean.plist')

module PodcastProducer
  module Actions
    class Videosize < Base
      def usage
        "videosize: get Quicktime or Mp4-alike movie- and render-dimensions\n\n" +
        "usage: videosize --prb=PRB --input=INPUT\n" +
        "                [--output=OUTPUT]    re-encode INPUT to OUTPUT if dimensions differ\n" +
        "                [--key=KEY]          KEY to lookup, forces the dimension if OUTPUT is given\n" +
        "                [--human]            display human readable values\n"
      end

      def options
        ["input*", "output", "key", "human"]
      end

      def run(arguments)
        require_plural_option(:inputs, 1, 1)

        input = $subcommand_options[:inputs][0]
        output = $subcommand_options[:output]
        human = $subcommand_options[:human]
        key = $subcommand_options[:key]

        has_video = McastQT.info(input,'hasVideo').to_s == '1'
        log_notice "has video track: " + has_video.to_s
        log_crit_and_exit("Missing video track", ERR_MISSING_VIDEOTRACK) unless has_video

        video_dimensions = {}

        movie_width = McastQT.info(input,'width').to_i
        log_notice "movie width: " + movie_width.to_s
        log_crit_and_exit("invalid width", ERR_INVALID_WIDTH) unless movie_width > 0
        video_dimensions[:movie_width] = movie_width

        movie_height = McastQT.info(input,'height').to_i
        log_notice "movie height: " + movie_height.to_s
        log_crit_and_exit("invalid height", ERR_INVALID_HEIGHT) unless movie_height > 0
        video_dimensions[:movie_height] = movie_height

        movie_ratio = movie_width.to_f / movie_height.to_f
        movie_ratio = McastQT.lookup_aspect_ratio(movie_ratio) if human && !output
        log_notice "movie ratio: " + movie_ratio.to_s
        video_dimensions[:movie_ratio] = movie_ratio

        MOVIE_DIMENSION_FLAVORS.each do |flavor, mode|
          flavor = flavor.to_s
          log_notice "processing flavor: " + flavor
          width, height = McastQT.lookup_dimensions(input, mode)
  
          log_notice flavor + " width: " + width.to_s
          log_crit_and_exit(flavor + " width invalid", ERR_INVALID_WIDTH) unless width > 0
          video_dimensions[(mode.to_s + "_width").to_sym] = width
  
          log_notice flavor + " height: " + height.to_s
          log_crit_and_exit(flavor + " height invalid", ERR_INVALID_HEIGHT) unless height > 0
          video_dimensions[(flavor + "_height").to_sym] = height
  
          ratio = width.to_f / height.to_f
          ratio = McastQT.lookup_aspect_ratio(ratio) if human && !output
          log_notice flavor + " ratio: " + ratio.to_s
          video_dimensions[(flavor + "_ratio").to_sym] = ratio
        end

        if key
          log_crit_and_exit("invalid key", ERR_INVALID_KEY) unless
            ["movie_width", "movie_height", "movie_ratio",
             "track_width", "track_height", "track_ratio",
             "clean_width", "clean_height", "clean_ratio",
             "prod_width",  "prod_height",  "prod_ratio"].include?(key.to_s)
        end
        if output
          force = {:force => key,:dims => video_dimensions} if key
          log_notice('clean encoder: ' + MCP_VIDEOSIZE_CLEANER.to_s)
          if File.exist?(MCP_VIDEOSIZE_CLEANER) && !File.directory?(MCP_VIDEOSIZE_CLEANER)
            settings = MCP_VIDEOSIZE_CLEANER
          else
            require_encoder(MCP_VIDEOSIZE_CLEANER)
            settings = settings_for_encoder(MCP_VIDEOSIZE_CLEANER)
          end
          begin
#            log_notice('clean settings: ' + settings.to_s)
            result = McastQT.correct_aspect_ratio(input, output, settings, force)
            # puts result.to_s
          rescue PcastException => e
            log_crit_and_exit(e.message, e.return_code.to_i)
#          rescue Exception => e
#            log_crit_and_exit(e.message, 1)
          end
        elsif key
          puts video_dimensions[key.to_sym].to_s
        end
      end
    end

  end
end
