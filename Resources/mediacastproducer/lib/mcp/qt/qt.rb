#!/usr/bin/env ruby -I/usr/lib/podcastproducer
#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2009 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'fileutils'
require 'common/pcast_exception'
require 'qt/qt'
require 'mcp/constants'

MOVIE_DIMENSION_FLAVORS = { :track => OSX::QTTrackDimensionsAttribute, 
                            :clean => OSX::QTMovieApertureModeClean,
                            :prod => OSX::QTMovieApertureModeProduction }

class McastQT < PcastQT

  def self.encode(input, output, settings)
    output_path = self.verify_input_and_output_paths_are_not_equal(input, output)
    input_movie = self.load_movie(input)
    return false unless input_movie
    input_movie.setAttribute_forKey(true, OSX::QTMovieEditableAttribute)
    settings_dictionary = OSX::NSDictionary.dictionaryWithContentsOfFile(settings)
    component_subtype = OSX::QTOSTypeForString(settings_dictionary["componentSubtype"])
    component_manufacturer = OSX::QTOSTypeForString(settings_dictionary["componentManufacturer"])
    atom_container_data = settings_dictionary["atomContainerData"]
    enable_audio_tracks = settings_dictionary["enableAudioTracks"]
    enable_audio_tracks ||= 1
    enable_video_tracks = settings_dictionary["enableVideoTracks"]
    enable_video_tracks ||= 1
    clean_aperture_mode = settings_dictionary["useCleanApertureMode"]
    clean_aperture_mode ||= 1
    componentPresetName = settings_dictionary["componentPresetName"]
    
    duration = input_movie.attributeForKey(OSX::QTMovieDurationAttribute).QTTimeValue
    
    attributes = {
      OSX::QTMovieExport => true,
      OSX::QTMovieExportType => component_subtype,
      OSX::QTMovieExportManufacturer => component_manufacturer,
    }    
    
    if componentPresetName
      attributes["QTMovieExportPresetName"] = componentPresetName
    end

    if clean_aperture_mode == 1
      input_movie.setAttribute_forKey(OSX::QTMovieApertureModeClean, OSX::QTMovieApertureModeAttribute)
    end
    
    if enable_audio_tracks == 0 
      input_movie.tracks.each do |track|
        media_type = track.media.attributeForKey(OSX::QTMediaTypeAttribute)
        if media_type == OSX::QTMediaTypeSound
          input_movie.removeTrack(track) 
          log_notice "Removing audio tracks"
        end
      end
    end
    
    if enable_video_tracks == 0
      input_movie.tracks.each do |track|
        media_type = track.media.attributeForKey(OSX::QTMediaTypeAttribute)
        if media_type == OSX::QTMediaTypeVideo or media_type == OSX::QTMediaTypeQuartzComposer
          input_movie.removeTrack(track) 
          log_notice "Removing video tracks"
        end
      end
    end
      
    if ((enable_audio_tracks == 1) && (enable_video_tracks == 0) && PcastQT.info(input, "hasAudio") == "0")
      silence_movie = self.load_movie(SILENCE_MOVIE)

      qt_from_range = OSX::QTMakeTimeRange(OSX::QTZeroTime, silence_movie.duration)
      qt_to_range = OSX::QTMakeTimeRange(OSX::QTZeroTime, input_movie.duration)
      
      input_movie.insertSegmentOfMovie_fromRange_scaledToRange(silence_movie, qt_from_range, qt_to_range)
    end
        
    attributes[OSX::QTMovieExportSettings] = atom_container_data if atom_container_data
    delegate = PcastQTMovieDelegate.alloc.init
    input_movie.setDelegate(delegate)
    random_string = Time.now.to_i.to_s + "_" + PcastUUID.new.gen_uuid
    non_chapterized_output_path = File.basename(output, ".*").gsub(/[:\/]/, "_") + "-non_chapterized-" + random_string + File.extname(output)
    error = nil
    success, error = input_movie.writeToFile_withAttributes_error(non_chapterized_output_path, attributes)
    unless success
      log_error "could not save the movie: #{error.localizedDescription}" 
      return false
    end
    
    ext = File.extname(non_chapterized_output_path)
    if ext == ".mov" || ext == ".m4a" || ext == ".m4b" || ext == ".m4v"
      chapters = self.backup_chapters(input)
      if chapters
        if self.restore_chapters(non_chapterized_output_path, output_path, chapters, component_subtype, component_manufacturer) 
          return true
        else
          log_error("Failed to restore chapters") 
        end
      end
    end

    FileUtils.mv(non_chapterized_output_path, output_path) if File.exist?(non_chapterized_output_path)
    return true
  end

  def self.reference(destination, urls_by_tier)
    rmdas = []
    rmdaslength = 0
    
    iphone_rmdas = []
    iphone_rmdaslength = 0
    
    ipad_rmdas = []
    ipad_rmdaslength = 0
    
    datarates_by_tier = { :edge => "11200", :wifi => "100000", :desktop => "150000", # "2147483647"
                          :iphone_edge => "11200", :iphone_wifi => "100000",
                          :ipad_edge => "11200", :ipad_wifi => "100000"}
    
    urls_by_tier.each do |tier, url|
      
      is_iphone = tier.to_s =~ /^iphone_/
      is_ipad = tier.to_s =~ /^ipad_/
      datarate = datarates_by_tier[tier]
      
      # Data Reference Atom
      # Size (5 * long + url + 1) + Type ('rdrf') + Flags (not self-contained = null) + Data Reference Type ('url ') + Data Reference Size + Data Reference (null terminated)
      rdrf = [(21 + url.length)].pack("N") + "rdrf" + [0].pack("N") + "url " + [(url.length + 1)].pack("N") + url + "\0"
      
      # Data Rate Atom
      # Size (4 * long) + Type ('rmdr') + Flags (always null) + Data Rate (bits/s)
      rmdr = [16].pack("N") + "rmdr" + [0].pack("N") + [datarate.to_i].pack("N")
      
      # Reference Movie Descriptor Atom
      # Size (rdrf + rmdr + 2 * long) + Type ('rmda') + Data Reference Atom + Data Rate Atom
      rmda = [(45 + url.length)].pack("N") + "rmda" + rdrf + rmdr
      
      unless is_iphone || is_ipad
        rmdas.push(rmda)
        rmdaslength += rmda.length
      end
      
      # iPhone-specific atoms
      if is_iphone || is_ipad
        idev_version = is_ipad ? "16" : "1"
        # Version Check Atom
        # Size (4 * long) + Type ('rmvc') + Flags (always null) + Software Package ('mobi') + Version (1) + Mask (1) + Check Type 16-bit (1)
        idev_rmvc = [26].pack("N") + "rmvc" + [0].pack("N") + "mobi" + [idev_version.to_i].pack("N") + [1].pack("N") + [1].pack("n")
        
        # Reference Movie Descriptor Atom
        # Size (rdrf + rmdr + 2 * long) + Type ('rmda') + Data Reference Atom + Data Rate Atom + Version Check Atom
        idev_rmda = [(71 + url.length)].pack("N") + "rmda" + rdrf + rmdr + idev_rmvc
        
        if is_ipad
          ipad_rmdas.push(idev_rmda)
          ipad_rmdaslength += idev_rmda.length
        end
        if is_iphone
          iphone_rmdas.push(idev_rmda)
          iphone_rmdaslength += idev_rmda.length
        end
      end
      
    end
    
    rmdas += ipad_rmdas + iphone_rmdas
    rmdaslength += ipad_rmdaslength + iphone_rmdaslength

    # Reference Movie Atom
    # Size (2 * long + descriptor length) + Type ('rmra') + Reference Movie Descriptor Atoms
    rmra = [(8 + rmdaslength)].pack("N") + "rmra" + rmdas.join('')

    # Movie Atom
    # Size (2 * long + reference movie length) + Type ('moov') + Reference Movies
    moov = [(16 + rmdaslength)].pack("N") + "moov" + rmra

    begin
      file = File.new(destination, File::WRONLY|File::TRUNC|File::CREAT)
      file.print moov
      file.close
    rescue
      log_error "An error occurred writing reference movie file"
      return false
    end
    return true
  end
  
  def self.is_streamable?(input)
    atoms = %w(free junk mdat moov pnot skip wide PICT ftyp cmov stco co64)
    File.open(input) do |f|
      while !f.eof?
        # the size is an unsigned 32bit integer, big-endian AKA network byte order
        # the type is 4 ascii characters
        size, type = f.read(8).unpack("Na4")
        raise ArgumentError, "unknown atom type #{type} in #{input} at #{f.pos}" unless atoms.include?(type)
        return f.pos < 0xff if type == "moov"
        f.seek(size - 8, IO::SEEK_CUR)
      end
      raise ArgumentError, "no moov atom found"
    end
  rescue Exception => e
    log_error(e.to_s + ": " + e.message)
    return false
  end
  
  def self.lookup_dimensions(input,
                             mode = OSX::QTMovieApertureModeClean,
                             key = nil,
                             desired_types = [OSX::QTMediaTypeVideo])
    sizes = {}
    if key
      log_crit_and_exit("invalid key",ERR_INVALID_KEY) unless 
        ["width", "height"].include?(key)
      sizes[key.to_sym] = nil
    else
      sizes[:width] = nil
      sizes[:height] = nil
    end
    input_movie = self.load_movie(input)
    return false unless input_movie
#    log_notice("input movie: " + input_movie.to_s)
#    log_notice("input movie tracks: " + input_movie.tracks.to_s)
    dimensions = nil
    input_movie.tracks.each do |track|
#      log_notice("track:" + track.to_s)
      media_type = track.media.attributeForKey(OSX::QTMediaTypeAttribute)
#      log_notice("media type:" + media_type.to_s)
      if desired_types.include?(media_type)
#        log_notice("processing desired type")
        if mode == OSX::QTTrackDimensionsAttribute
          dimensions = track.attributeForKey(OSX::QTTrackDimensionsAttribute).sizeValue
          dimensions = {:width => dimensions.width, :height => dimensions.height}
#          log_notice("dimensions: " + dimensions[:width].to_s + " x " + dimensions[:height].to_s)
        else
          has_aperture = track.attributeForKey(OSX::QTTrackHasApertureModeDimensionsAttribute)
#          log_notice("has aperture: " + has_aperture.to_s)
          next unless has_aperture
          dimensions = track.apertureModeDimensionsForMode(mode)
          dimensions = {:width => dimensions.width, :height => dimensions.height}
#          log_notice("dimensions: " + dimensions[:width].to_s + " x " + dimensions[:height].to_s)
        end
      else
#        log_notice("skipped not desired track")
      end
      break if dimensions
    end
    log_notice("no dimensions found." + dimensions.to_s) unless dimensions
    sizes.each do |size_key,size_val|
      size_val = -1 if size_val.nil?
      if dimensions
        case size_key
        when :width
#          log_notice("processing key:" + size_key.to_s)
          size_val = dimensions[size_key.to_sym]
        when :height
#          log_notice("processing key:" + size_key.to_s)
          size_val = dimensions[size_key.to_sym]
        else
          log_error("invalid key:" + size_key.to_s)
        end
#        log_notice("processed value: " + size_val.to_s)
      end
      return size_val if key == size_key.to_s
      sizes[size_key] = size_val
    end
    return sizes[:width], sizes[:height]
  rescue
    return -1 if key
    return -1,-1
  end

  def self.lookup_aspect_ratio(ratio, ratios=nil)
    aspect_ratio = ratio.to_f
    aspect_ratios = DEFAULT_ASPTECT_RATIOS if ratios.nil?
#    log_notice('aspect ratio: ' + aspect_ratio.to_s)
    aspect_ratios.each do |name|
      w, h = name.to_s.split(':')
#      log_notice('comparing: ' + name)
#      log_notice('comparing width/height: ' + w.to_s + "/" + h.to_s) 
      ratio = w.to_f / h.to_f
#      log_notice('comparing ratio: ' + ratio.to_s)
      equal_ratios = (ratio==aspect_ratio)
#      log_notice((equal_ratios ? 'ratios equal: ' : 'skipping ratio: ') + name.to_s)
      next unless equal_ratios
      return name
      break
    end
    return aspect_ratio.to_s
  end

  def self.correct_aspect_ratio(input, output, settings, force=nil)
    raise PcastException.new(ERR_MISSING_INPUT, "Missing INPUT file: " + input.to_s) unless File.exist?(input)
    raise PcastException.new(ERR_OUTPUT_EXISTS, "OUTPUT file already exists: " + output.to_s) if File.exist?(output)
#    exec_args = [MCP, 'encode', "--basedir=.",
#                 "--input", input.to_s,
#                 "--output", output.to_s,
#                 "--encoder", MOVIE_SIZE_CLEANER.to_s]
#    log_notice('executing: ' + exec_args.join(' ').to_s)
    self.encode(input,output,settings)
  end

  def self.verify_input_and_output_paths_are_not_equal(input, output)
    if (File.expand_path(input) == File.expand_path(output))
      raise PcastException.new(ERR_EDITING_INPLACE, "Cannot modify files in place.")
    else
      return output
    end
  end
end
