#!/usr/bin/arch -arch i386 /usr/bin/ruby -I/usr/lib/podcastproducer
#  REMIND: <rdar://problem/6158567> WORKAROUND: Force 32-bit execution for pcastaction
#
#  Copyright (c) 2006-2009 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'fileutils'
require 'pathname'

MCP_DIR = File.dirname(File.dirname(Pathname.new(__FILE__).realpath))
MCP_BIN = File.join(MCP_DIR,'bin')
MCP_LIB = File.join(MCP_DIR,'lib')
MCP_LIBEXEC = File.join(MCP_DIR,'libexec')
MCP_RES = File.dirname(MCP_DIR)
MCP = File.join(MCP_BIN, 'mediacastproducer')
MCE = File.join(MCP_BIN, 'mediacastencoder')

$LOAD_PATH.push(File.expand_path(MCP_LIB)) unless 
  $LOAD_PATH.include?(MCP_LIB) || $LOAD_PATH.include?(File.expand_path(MCP_LIB))
#$LOAD_PATH.each do |path|
#  puts path
#end

### globals

$productinfo ={ :name => 'Mediacast Encoder',
                :version => '0.1',
                :command => File.basename($0,'.rb')}

require 'mcp/main'
require 'mcp/transcoder'
require 'mcp/encoder'

### run

begin
  Encoder.run(MediacastProducer::Transcoder::options_list)
rescue
  $stderr.puts $!.class.name + ": " + $!.message
  $!.backtrace.each { |frame| $stderr.puts "\tfrom " + frame }
  exit(-1)
end
