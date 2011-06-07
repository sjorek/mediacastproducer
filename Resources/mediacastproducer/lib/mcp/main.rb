#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'etc'

ENV["HOME"] = ENV["CFFIXED_USER_HOME"] = "/var/empty" unless File.directory?(Etc.getpwuid(Process.euid != 0 ? Process.euid : Process.uid).dir) rescue false # this must be done prior to loading RubyCocoa

require 'getoptlong'
require 'osx/cocoa'
require 'ftools'
require 'fileutils'
require 'date'
require 'erb'
require 'yaml'
require '/usr/lib/podcastproducer/pcast_ruby' 
require 'pathname'
require 'mcp/mcast_common'

ASL.enable_logging_to_stderr(true)

ENV["CI_NO_ACCEL"] = "1"

# Suppressing CGS error message (6676888) 
cg = DL.dlopen('//System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/CoreGraphics')
cg['CGSSetShouldLogMessages', '0I'].call(0)
cg['CGSSetShouldLogErrors', '0I'].call(0)


### globals

$subcommands = []
$subcommand_options = {}
$properties = {}
$no_fail = false
$pcastaction_version = 0

$default_qc_width = 1024
$default_qc_height = 768
### helpers

def print_version
  $stderr.puts "#{$productinfo[:name]} action task, version #{$productinfo[:version]}"
  $stderr.puts "Copyright 2011 Stephan Jorek"
  $stderr.puts "based upon:"
  $stderr.puts "Podcast Producer action task, version 2.0"
  $stderr.puts "Copyright 2007 Apple, Inc."
  $stderr.puts
end

def print_usage
  print_version
  $stderr.puts "usage: #{$productinfo[:command]} <subcommand> [options] [args]"
  $stderr.puts "Type '#{$productinfo[:command]} help <subcommand>' for help on a specific subcommand."
  $stderr.puts
  $stderr.puts "Available subcommands:"
  $subcommands.sort! {|x,y| x.name <=> y.name}
  $subcommands.each do |subcommand|
    $stderr.puts "  " + subcommand.name
  end
  $stderr.puts
  $stderr.puts "By specifying '--no_fail' #{$productinfo[:command]} will ignore any failures and always exit with an exit code of 0."
  $stderr.puts
end

def print_subcommand_usage(subcommand_name)
  print_version
  subcommand = subcommand_with_name(subcommand_name)
  if subcommand.nil?
    $stderr.puts "\"#{subcommand_name}\": unknown command"
    $stderr.puts
  else
    $stderr.puts subcommand.usage
    $stderr.puts
  end
end

def get_plist_opts_from_stdin
  plist_opts = nil
  begin
    stdin_string = $stdin.read
    stdin_nsstring = stdin_string.to_ns if stdin_string
    stdin_nsplist = stdin_nsstring.propertyList if stdin_nsstring
    stdin_plist = stdin_nsplist.to_ruby if stdin_nsplist
    if stdin_plist && (stdin_plist.kind_of?(Hash) || stdin_plist.kind_of?(Array))
      plist_opts = stdin_plist.collect { |option_key, option_value| ["--#{option_key}", option_value] }
    end
  rescue
    # plist_opts will be nil if the plist can't be read
  end
  return plist_opts
end

def plist_opts_validation_error(plist_opts, allowed_opts)
  allowed_opts_types = {}
  allowed_opts.each do |allowed_opt|
    allowed_opts_types[allowed_opt.first] = allowed_opt.last
  end
  plist_opts.each do |plist_opt_key, plist_opt_value|
    return "unrecognized option `#{plist_opt_key}'" unless allowed_opts_types[plist_opt_key]
  end
  return nil
end

def subcommand_with_name(subcommand_name)
  $subcommands.find {|obj| obj.name == subcommand_name}
end

def read_properties
  properties_filename = "properties.plist"
  prb_path = $subcommand_options[:prb]
  if prb_path
    metadata_folder_properties_filepath = File.join(File.expand_path(prb_path), "Contents", "Resources", "Metadata", properties_filename)
  end
  
  if File.exist?(properties_filename)
    ns_properties = OSX::NSDictionary.dictionaryWithContentsOfFile(properties_filename)
  elsif metadata_folder_properties_filepath && File.exist?(metadata_folder_properties_filepath)
    ns_properties = OSX::NSDictionary.dictionaryWithContentsOfFile(metadata_folder_properties_filepath)
  end

  properties = {}
  
  if ns_properties
    ns_properties.allKeys.each do |key|
      properties[key.to_s] = ns_properties[key].to_ruby
    end
  end

  encrypted_properties_filename = "encrypted_properties.plist"
  encryption_key = properties["Encrypted Properties Encryption Key"]
  if encryption_key
    if prb_path
      encrypted_properties_filepath = File.join(File.expand_path(prb_path), "Contents", "Resources", "Working", encrypted_properties_filename)
    end
  
    if encrypted_properties_filepath && File.exist?(encrypted_properties_filepath)
      ns_properties = OSX::NSDictionary.dictionaryWithContentsOfFile(encrypted_properties_filepath)
      if ns_properties
        ns_properties.allKeys.each do |key|
          properties[key.to_s] = Crypto.decrypt(encryption_key, ns_properties[key].to_ruby)
        end
      end
    end
  end
  properties["Global Resource Path"] = MCP_RES unless properties["Global Resource Path"]
#  log_notice("Global Resource Path: " + properties["Global Resource Path"])
#  properties.each do |pk,pv|
#    log_notice(pk.to_s + ": "+ pv.to_s)
#  end
  properties
end
