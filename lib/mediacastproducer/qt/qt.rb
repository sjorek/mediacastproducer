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
require 'mediacastproducer/constants'

MOVIE_DIMENSION_FLAVORS = { :track => OSX::QTTrackDimensionsAttribute, 
                            :clean => OSX::QTMovieApertureModeClean,
                            :prod => OSX::QTMovieApertureModeProduction }

MOVIE_SIZE_CLEANER = File.join(MCP_LIB, 'mediacastproducer', 'encodings', 'qt_clean_24fps_aac_192kbit_44100.plist') # 'qt_clean.plist')

class McastQT < PcastQT
  
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

  def self.correct_aspect_ratio(input, output, force=nil)
    raise PcastException.new(ERR_MISSING_INPUT, "Missing INPUT file: " + input.to_s) unless File.exist?(input)
    raise PcastException.new(ERR_OUTPUT_EXISTS, "OUTPUT file already exists: " + output.to_s) if File.exist?(output)
    exec_args = [MCP, 'encode', "--basedir=.",
                 "--input", input.to_s,
                 "--output", output.to_s,
                 "--encoder", MOVIE_SIZE_CLEANER.to_s]
    # log_notice('executing: ' + exec_args.join(' ').to_s)
    self.encode(input,output,MOVIE_SIZE_CLEANER)
  end

  def self.verify_input_and_output_paths_are_not_equal(input, output)
    if (File.expand_path(input) == File.expand_path(output))
      raise PcastException.new(ERR_EDITING_INPLACE, "Cannot modify files in place.")
    else
      return output
    end
  end
end
