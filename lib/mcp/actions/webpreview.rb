#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'dnssd'
require 'etc'
require 'fileutils'
require 'mcp/actions/base'

MCP_MEDIACASTSERVER = File.join(MCP_LIB,"mediacastserver")
MCS_TWISTED_DAEMON = '/usr/bin/twistd'
MCS_TWISTED_SERVER = File.join(MCP_MEDIACASTSERVER,"mcs/server.py")
MCS_REWRITE_PROXY  = File.join(MCP_MEDIACASTSERVER,"mcs/proxy.py")

module PodcastProducer
  module Actions
    class WebPreview < Base
      def usage
        "#{name}: starts a web- and optionally a proxy-server for preview purposes.\n\n" +
        "usage: #{name} --basedir=BASEDIR\n"+
        "                 [--verbose]    run with verbose output\n\n" +
        "web-server configuration:\n" +
        "                 [--web_vhost]  virtual hostname (FQDN) to serve\n" +
        "                 [--web_alias]  path alias rule(s)\n\n" +
        "web-proxy configuration:\n" +
        "                 [--proxy_rw]   hostname rewrite rule(s)\n" +
        "                 [--proxy_dl]   download bandwidth limit\n" +
        "                 [--proxy_ul]   upload bandwidth limit\n" +
        "                 [--proxy_ip]   IP adress to serve, default:\n" +
        "                                  all (locally) available IPs\n" +
        "                 [--proxy_if]   Network interface to serve, default:\n" +
        "                                  all (locally) available interfaces\n" +
        "                                IP adress and network interface\n" +
        "                                are mutually exclusive.\n"
      end

      def options
        ["web_vhost", "web_alias",
         "proxy_ip", "proxy_if", "proxy_rw", "proxy_dl", "proxy_ul"]
      end

      def run(arguments)

#        DNSSD.register 'block', '_http._tcp', nil, 8081 do |r|
#          puts "registered #{r.fullname}" if r.flags.add?
#        end
#
#        while true:
#          sleep 1
#        end
#        exit

        ENV["PYTHONPATH"] = MCP_MEDIACASTSERVER
        ENV["PYTHONDONTWRITEBYTECODE"] = "0"
        ENV["PYTHONIOENCODING"] = "utf8"
        args = [MCS_TWISTED_DAEMON, "--no_save", "--nodaemon", "--rundir=.",
                "mediacastserver"]
        args << "--logfile=mediacastserver.log" if $subcommand_options[:verbose].nil?
        log_notice("running: #{args.join(' ')}")
        pids, stdout = fork_chain_and_return_pids_and_stdout(args)
        log_crit_and_exit("failed to start mediacastserver", -1) unless pids
        begin
          if $subcommand_options[:verbose].nil?
            while true
              sleep(1)
            end
          else
            while line = stdout.gets
              puts line
            end
          end
        rescue SystemExit, Interrupt
          while line = stdout.gets
            puts line unless $subcommand_options[:verbose].nil?
          end
          Process.kill('HUP', pids[0])
        end
        pid, status = Process.waitpid2(pids[0])
        log_notice("pid: #{pid} exit status: #{status.exitstatus}")
        File.delete("mediacastserver.log") if $subcommand_options[:verbose].nil?
      end
    end
  end
end