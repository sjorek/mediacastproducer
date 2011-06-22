#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/actions/base'

TWISTED_DAEMON = '/usr/bin/twistd'
TWISTED_SERVER = File.join(MCP_LIBEXEC,"mp4-faststart.py")

module PodcastProducer
  module Actions
    class WebPreview < Base
      def usage
        "#{name}: starts a web- and a proxy-server for preview purposes.\n\n" +
        "usage: #{name} --basedir=BASEDIR\n"+
        "                 [--verbose]    run with verbose output\n"
        "                 [--web]        web-server adress to serve\n" +
        "                 [--proxy]      proxy-server adress to serve\n" +
        "                 [--bandwidth]  proxy-server bandwidth limit\n" +
        "                 [--rewrite]    proxy-server rewrite rules\n\n"
      end

      def options
        ["web", "proxy", "bandwidth", "rewrite"]
      end

      def run(arguments)
        
      end
    end
  end
end