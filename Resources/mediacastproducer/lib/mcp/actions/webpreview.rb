#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/actions/base'

MCP_TWISTED_DAEMON = '/usr/bin/twistd'
MCP_TWISTED_SERVER = File.join(MCP_RES,"httpserver/twistedweb.py")
MCP_REWRITE_PROXY  = File.join(MCP_RES,"httpserver/rewriteproxy.py")

module PodcastProducer
  module Actions
    class WebPreview < Base
      def usage
        "#{name}: starts a web- and a proxy-server for preview purposes.\n\n" +
        "usage: #{name} --basedir=BASEDIR\n"+
        "                 [--verbose]    run with verbose output\n"
        "                 [--web]        web-server adress to serve\n" +
        "                 [--proxy]      proxy-server adress to serve\n" +
        "                 [--rewrite]    proxy-server rewrite rules\n" +
        "                 [--bandwidth]  proxy-server download bandwidth limit\n\n"
      end

      def options
        ["web", "proxy", "bandwidth", "rewrite"]
      end

      def run(arguments)
        # export PYTHONDONTWRITEBYTECODE=0
        # twistd --no_save --nodaemon --rundir=. --python=Resources/httpserver/twistedweb.py
      end
    end
  end
end