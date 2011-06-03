#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2008 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'actions/base'
require 'mediacastproducer/qt/qt'
require 'fileutils'

module PodcastProducer
  module Actions

    class Reference < Base
      def usage
        "reference: copies a reference movie linking the input movies to\n" +
        "           the document root of a web server.  \n\n" +
        "usage: reference --basedir=BASEDIR --web_root=WEB_ROOT --web_url=WEB_URL\n"+
        "                 --title=TITLE\n" +
        "                 --edge_movie=EDGE --wifi_movie=WIFI --desktop_movie=DESKTOP\n" +
        "                 [--iphone_edge_movie=EDGE] [--iphone_wifi_movie=WIFI]\n" +
        "                 [--ipad_edge_movie=EDGE] [--ipad_wifi_movie=WIFI]\n" +
        "                 [--type=MIME_TYPE] [--outfile[=OUTFILE]] [--create_poster_image]\n\n"
      end
      def options
        ["web_root", "web_url", "title", "type", "outfile", "create_poster_image",
          "edge_movie", "wifi_movie", "desktop_movie",
          "iphone_edge_movie", "iphone_wifi_movie",
          "ipad_edge_movie", "ipad_wifi_movie"]
      end
      def run(arguments)
        $subcommand_options[:web_root] ||= $properties["Web Document Root"]
        $subcommand_options[:web_url] ||= $properties["Web URL"]
        $subcommand_options[:title] ||= $properties["Title"]

        require_option(:web_root)
        require_option(:web_url)
        require_option(:title)
        require_option(:desktop_movie)
        require_option(:edge_movie)
        require_option(:wifi_movie)

        $subcommand_options[:iphone_edge_movie] = $subcommand_options[:edge_movie] unless $subcommand_options[:iphone_edge_movie]
        $subcommand_options[:iphone_wifi_movie] = $subcommand_options[:wifi_movie] unless $subcommand_options[:iphone_wifi_movie]
        $subcommand_options[:ipad_edge_movie] = $subcommand_options[:edge_movie] unless $subcommand_options[:ipad_edge_movie]
        $subcommand_options[:ipad_wifi_movie] = $subcommand_options[:wifi_movie] unless $subcommand_options[:ipad_wifi_movie]

        movie_file = $subcommand_options[:desktop_movie] # || $subcommand_options[:wifi_movie] || $subcommand_options[:edge_movie]

        urlified_title = $subcommand_options[:title].gsub(/ /, "_")

        movie_width = McastQT.info(movie_file, "width").to_i
        movie_height = McastQT.info(movie_file, "height").to_i
        has_video_track = McastQT.info(movie_file, "hasVideo") == "1"

        publish_location = '/' # + ERB::Util.url_encode($subcommand_options[:title]) + '/'
        web_publish_folder = $subcommand_options[:web_root] + publish_location
        web_publish_base_url = $subcommand_options[:web_url] + publish_location

        original_file = "reference.mov"
        web_publish_filename = get_publish_filename(urlified_title, "ref", original_file, web_publish_folder)
        web_publish_filepath = web_publish_folder + web_publish_filename
        web_publish_url = web_publish_base_url + ERB::Util.url_encode(web_publish_filename)

        FileUtils.mkdir_p(web_publish_folder)

        multi_publish_folder = web_publish_folder
        multi_publish_base_url = web_publish_base_url
        multi_publish_filepaths_by_tier = {}
        multi_publish_urls_by_tier = {}
        movie_paths_by_tier = {}
        movie_paths_by_tier[:edge] = $subcommand_options[:edge_movie] # if $subcommand_options[:edge_movie]
        movie_paths_by_tier[:wifi] = $subcommand_options[:wifi_movie] # if $subcommand_options[:wifi_movie]
        movie_paths_by_tier[:desktop] = $subcommand_options[:desktop_movie] # if $subcommand_options[:desktop_movie]
        movie_paths_by_tier[:iphone_edge] = $subcommand_options[:iphone_edge_movie] # if $subcommand_options[:iphone_edge_movie]
        movie_paths_by_tier[:iphone_wifi] = $subcommand_options[:iphone_wifi_movie] # if $subcommand_options[:iphone_wifi_movie]
        movie_paths_by_tier[:ipad_edge] = $subcommand_options[:ipad_edge_movie] # if $subcommand_options[:ipad_edge_movie]
        movie_paths_by_tier[:ipad_wifi] = $subcommand_options[:ipad_wifi_movie] # if $subcommand_options[:ipad_wifi_movie]
#        movie_paths_by_tier.each do |tier, movie_path|
#          print tier, " ", movie_path, "\n"
#        end
        movie_tiers_by_path = {}
        [:edge, :wifi, :desktop, :iphone_edge, :iphone_wifi, :ipad_edge, :ipad_wifi].each do |tier|
          movie_path = movie_paths_by_tier[tier]
          equal_tier = movie_tiers_by_path[movie_path.to_sym]
          if equal_tier
            multi_publish_filepaths_by_tier[tier] = multi_publish_filepaths_by_tier[equal_tier]
            multi_publish_urls_by_tier[tier] = multi_publish_urls_by_tier[equal_tier]
            log_notice("skipped equal tier " + tier.to_s + " = " + equal_tier.to_s)
            next
          end
          log_notice("processing tier "  + tier.to_s)
          multi_publish_format = tier.to_s + "-ref"
          multi_publish_filename = get_publish_filename(urlified_title, multi_publish_format, movie_path, multi_publish_folder)
          multi_publish_filepath = multi_publish_folder + multi_publish_filename
          multi_publish_url = multi_publish_base_url + ERB::Util.url_encode(multi_publish_filename)
          
          check_input_file(movie_path)
          check_output_file(multi_publish_filepath)
          FileUtils.cp(movie_path, multi_publish_filepath)
          FileUtils.chmod_R(0644, multi_publish_filepath)
          multi_publish_filepaths_by_tier[tier] = multi_publish_filepath
          multi_publish_urls_by_tier[tier] = multi_publish_url
          movie_tiers_by_path[movie_path.to_sym] = tier
        end
        McastQT.reference(web_publish_filepath, multi_publish_urls_by_tier) || exit(-1)

        web_publish_size = File.stat(web_publish_filepath).size.to_s

        if $subcommand_options[:create_poster_image]
          poster_filename = get_poster_filename(urlified_title, 'ref', movie_file, web_publish_folder)
          poster_filepath = web_publish_folder + poster_filename
          poster_url = web_publish_base_url + ERB::Util.url_encode(poster_filename)

          if has_video_track
            McastQT.posterimage(movie_file, poster_filepath) || exit(-1)
          else
            audio_file_icon_path = $properties["Global Resource Path"] + "/Images/audio_file_icon.png"
            check_input_file(audio_file_icon_path)
            check_output_file(poster_filepath)
            FileUtils.cp(audio_file_icon_path , poster_filepath)
            FileUtils.chmod_R(0644, poster_filepath)
            movie_width = McastQT.info(poster_filepath, "width").to_i
            movie_height = McastQT.info(poster_filepath, "height").to_i
          end
        end

        unless $subcommand_options[:outfile].nil?
          if $subcommand_options[:outfile].empty?
            outfile = "publish_description_file.txt"
          else 
            outfile = $subcommand_options[:outfile]
          end
          publish_description = {
            :path => web_publish_filepath,
            :url => web_publish_url,
            :size => web_publish_size
          }
          publish_description[:width] = movie_width.to_s unless movie_width.nil?
          publish_description[:height] = movie_height.to_s unless movie_height.nil?
          publish_description[:tag] = 'ref' # multi
          publish_description[:type] = $subcommand_options[:type] unless $subcommand_options[:type].nil?
          if $subcommand_options[:create_poster_image]
            publish_description[:poster_path] = poster_filepath
            publish_description[:poster_url] = poster_url
          end
          multi_publish_filepaths_by_tier.each do |tier, multi_publish_filepath|
            publish_description[(tier.to_s + "_path").to_sym] = multi_publish_filepath
          end
          multi_publish_urls_by_tier.each do |tier, multi_publish_url|
            publish_description[(tier.to_s + "_url").to_sym] = multi_publish_url
          end
          File.open(outfile, "w") do |file|
            file.puts publish_description.to_yaml
          end
        end
      end
    end
    
  end
end
