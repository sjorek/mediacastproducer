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

require 'actions'

require 'pathname'
$LOAD_PATH.unshift(File.expand_path(File.dirname(Pathname.new(__FILE__).realpath))) unless 
  $LOAD_PATH.include?(File.dirname(Pathname.new(__FILE__).realpath)) || $LOAD_PATH.include?(File.expand_path(File.dirname(Pathname.new(__FILE__).realpath)))

require 'mcactions'

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
  $stderr.puts "Mediacast Producer action task, version 0.1"
  $stderr.puts "Copyright 2011 Stephan Jorek"
  $stderr.puts "based upon:"
  $stderr.puts "Podcast Producer action task, version 2.0"
  $stderr.puts "Copyright 2007 Apple, Inc."
  $stderr.puts
end

def print_usage
  print_version
  $stderr.puts "usage: mediacastproducer <subcommand> [options] [args]"
  $stderr.puts "Type 'mediacastproducer help <subcommand>' for help on a specific subcommand."
  $stderr.puts
  $stderr.puts "Available subcommands:"
  $subcommands.sort! {|x,y| x.name <=> y.name}
  $subcommands.each do |subcommand|
    $stderr.puts "  " + subcommand.name
  end
  $stderr.puts
  $stderr.puts "By specifying '--no_fail' mediacastproducer will ignore any failures and always exit with an exit code of 0."
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
  
  properties
end

PodcastProducer::Actions.load_actions

$subcommands = PodcastProducer::Actions.action_instances

### main

class Main
  def self.run

    if ARGV.length == 0
      print_usage
      exit
    end

    subcommand_name = ARGV.shift
    if ['--help', '-h', 'help'].include? subcommand_name
      if ARGV.length > 0
        while subcommand_name = ARGV.shift
          print_subcommand_usage subcommand_name
        end
      else
        print_usage
      end
      exit
    elsif ['--version', '-V'].include? subcommand_name
      print_version
      exit
    elsif ['--plistin'].include? subcommand_name
      subcommand_name = nil
    else
      subcommand = subcommand_with_name(subcommand_name)
      if subcommand.nil?
        print_subcommand_usage(subcommand_name)
        exit(-1)
      end
    end
    
    # if ARGV.length == 0 
    #   print_subcommand_usage(subcommand_name)
    #   exit
    # end
    
    getopt_args = [["--basedir", GetoptLong::OPTIONAL_ARGUMENT], ["--prb", GetoptLong::OPTIONAL_ARGUMENT], ["--no_fail", GetoptLong::OPTIONAL_ARGUMENT],  ["--subcommand", GetoptLong::OPTIONAL_ARGUMENT],  ["--password_property", GetoptLong::OPTIONAL_ARGUMENT]]
    plural_options = []
    
    PodcastProducer::Actions.options_list.each do |option|
      if option[-1..-1] == "*"
        option = option[0..-2] 
        plural_option = option + "s"
        plural_options << plural_option
      end
      getopt_args << ["--#{option}", GetoptLong::OPTIONAL_ARGUMENT]
    end
    
    passed_args = ARGV.join(" ")
    
    if subcommand_name.nil?
      subcommand_getopt = get_plist_opts_from_stdin
      ASLLogger.crit_and_exit("An error occurred while reading the property list from standard input") unless subcommand_getopt
      validation_error = plist_opts_validation_error(subcommand_getopt, getopt_args)
      ASLLogger.crit_and_exit(validation_error) if validation_error
    else
      subcommand_getopt = GetoptLong.new(*getopt_args)
    end
    
    subcommand_getopt.each do |option, value|
      case option
        when /--subcommand/
          subcommand_name = value
          subcommand = subcommand_with_name(subcommand_name)
          if subcommand.nil?
            print_subcommand_usage(subcommand_name)
            exit
          end
        when /--(.*)/
          name = $1
          plural_name = name + "s"
          if plural_options.include?(plural_name)
            $subcommand_options[plural_name.to_sym] ||= []
            $subcommand_options[plural_name.to_sym] << value
          else
            $subcommand_options[name.to_sym] = value
          end
      end
    end

    if subcommand_name.nil?
      print_usage
      exit
    end

    if !$subcommand_options[:basedir].nil?
      if !$subcommand_options[:prb].nil?
        log_crit_and_exit("Both --basedir and --prb were specified. Please specify one and only one of these parameters.", -1)
      end
      $pcastaction_version = 1
      $working_directory = File.expand_path($subcommand_options[:basedir])
      $subcommand_options[:basedir] = File.expand_path($subcommand_options[:basedir])
    elsif !$subcommand_options[:prb].nil?
      $pcastaction_version = 2
      prb_path = File.expand_path($subcommand_options[:prb])
      log_crit_and_exit("You do not the correct permissions for this action.") unless File.writable?(prb_path)
      $subcommand_options[:prb] = File.expand_path($subcommand_options[:prb])
      $working_directory = "#{prb_path}/Contents/Resources/Working"
      if not File.exists?($working_directory)
        FileUtils.mkdir_p($working_directory)
      end
    else 
      log_crit_and_exit("Neither --basedir nor --prb were specified. Please specify one and only one of these parameters.", -1)
    end
    
    $no_fail = !$subcommand_options[:no_fail].nil?
    
    log_crit_and_exit("Working directory ('#{$working_directory}') does not exist.") unless File.exists?($working_directory)
    log_crit_and_exit("Working directory ('#{$working_directory}') is not a directory.") unless File.directory?($working_directory)
    log_crit_and_exit("Working directory ('#{$working_directory}') is not readable.") unless File.readable?($working_directory)
    log_crit_and_exit("Working directory ('#{$working_directory}') is not writable.") unless File.writable?($working_directory)

    Dir.chdir $working_directory
    
    $properties = read_properties
    
    unless $subcommand_options[:password]
      password_property = $subcommand_options[:password_property]
      $subcommand_options[:password] = $properties[password_property] if password_property
    end
    
    sanitized_arguments = passed_args.gsub(/--(master_)?pass(word)?(=|\s)(\".*\"|\S*)/, '--\1pass\2=*****')
    subcommand.log_notice("START: [Working directory: #{$working_directory}] {Arguments: #{sanitized_arguments}} v.#{$pcastaction_version}")
    subcommand.run(ARGV)
    subcommand.log_notice("FINISH")
    
  end
end

### run

begin
  Main.run
rescue
  $stderr.puts $!.class.name + ": " + $!.message
  $!.backtrace.each { |frame| $stderr.puts "\tfrom " + frame }
  exit(-1)
end
