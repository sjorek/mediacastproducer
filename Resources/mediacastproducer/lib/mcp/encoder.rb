#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

$transcoder_engine = nil
$transcoder_preset = nil
$subcommands_loaded = false

$subcommand_is_help = ARGV.length == 0 || ['--help', '-h', 'help'].include?(ARGV[0])

def load_subcommands
  unless $subcommands_loaded
    log_notice('load_subcommands called')
    $subcommands_loaded = true
    MediacastProducer::Transcoder.load_actions
    $subcommands = MediacastProducer::Transcoder.action_instances
  else
    log_notice('load_subcommands skipped')
  end
end

def options_list
  load_subcommands
  MediacastProducer::Transcoder.options_list
end

def subcommand_with_name(subcommand_name)
  if subcommand_name =~ /(.*)\/(.*)/
    $transcoder_engine = $1
    $transcoder_preset = $2
    subcommand_name = $transcoder_engine
    unless $subcommand_is_help
      ARGV.push("--preset=\"#{$transcoder_preset}\"")
    end
  end
  load_subcommands
  $subcommands.find {|obj| obj.name == subcommand_name}
end

alias _print_usage print_usage

def print_usage
  load_subcommands
  _print_usage
end

### Encoder

class Encoder
  def self.run()

    $properties = read_properties

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
    
    options_list.each do |option|
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
    
#    if !$subcommand_options[:preset].nil?
#      $transcoder_engine = subcommand_name
#      $transcoder_preset = $subcommand_options[:preset]
#    else 
#      log_crit_and_exit("No preset specified. Please specify one.", -1)
#    end
    
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
    subcommand.log_notice("START: [Working directory: #{$working_directory}] {Arguments: #{sanitized_arguments}} v.#{$productinfo[:version]}")
    subcommand.run(ARGV)
    subcommand.log_notice("FINISH")
    
  end
end