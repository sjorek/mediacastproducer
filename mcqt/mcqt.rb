#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2009 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'qt/qt'

class McastQT < PcastQT
  
  def self.reference(destination, urls_by_tier)
    rmdas = []
    rmdaslength = 0
    
    iphone_rmdas = []
    iphone_rmdaslength = 0
    
    datarates_by_tier = { :edge => "11200", :wifi => "100000", :desktop => "2147483647" }
    
    urls_by_tier.each do |tier, url|
      
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
      
      rmdas.push(rmda)
      rmdaslength += rmda.length
      
      # iPhone-specific atoms
      if datarate.to_i == 11200 or datarate.to_i == 100000  
            
        # Version Check Atom
        # Size (4 * long) + Type ('rmvc') + Flags (always null) + Software Package ('mobi') + Version (1) + Mask (1) + Check Type 16-bit (1)
        rmvc = [26].pack("N") + "rmvc" + [0].pack("N") + "mobi" + [1].pack("N") + [1].pack("N") + [1].pack("n")

        # Reference Movie Descriptor Atom
        # Size (rdrf + rmdr + 2 * long) + Type ('rmda') + Data Reference Atom + Data Rate Atom + Version Check Atom
        iphone_rmda = [(71 + url.length)].pack("N") + "rmda" + rdrf + rmdr + rmvc

        iphone_rmdas.push(iphone_rmda)
        iphone_rmdaslength += iphone_rmda.length

      end
      
    end
    
    rmdas += iphone_rmdas
    rmdaslength += iphone_rmdaslength

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
end
