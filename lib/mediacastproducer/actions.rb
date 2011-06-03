#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'actions'
require 'cgi' # this fixes "NameError: uninitialized constant CGI" issue from the library above

module PodcastProducer
  module Actions
  
    def self.load_actions
      Dir["/usr/lib/podcastproducer/actions/*.rb"].each do |path|
        name = File.join(File.dirname(path), File.basename(path, ".rb"))
        require name
      end
#      puts MCP_LIB_DIR
      Dir[File.join(File.expand_path(MCP_LIB_DIR), "mediacastproducer/actions/*.rb")].each do |path|
#        puts path
        name = File.join(File.dirname(path), File.basename(path, ".rb"))
#        puts name
        require name
      end
    end
    
  end
end
