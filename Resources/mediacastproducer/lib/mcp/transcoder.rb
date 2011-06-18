#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'shellwords'
require 'mcp/common/mcast_exception'
require 'mcp/actions/base'
require 'mcp/plist/script_preset'
require 'mcp/common/templates'
require 'mcp/common/asl_class_logging'

module MediacastProducer
  module Transcoder
    module Script
      def run_script(arguments)
        data_values = {}
        raw_values = {}
        script.sanatize_options { |option, value, raw|
          data_values[option] = value
          raw_values[option] = raw
        }
        data_values['input'] = input
        data_values['output'] = output
        raw_values.update(MediacastProducer::Transcoder.file_values(input,'input_'))
        raw_values.update(MediacastProducer::Transcoder.file_values(output,'output_'))
        tools = []
        script.commands.each do |c|
          tool = tool_with_name(c)
          log_crit_and_exit("tool #{c} not found",ERR_TOOL_FAILURE) if tool.nil?
          log_crit_and_exit("failed to setup tools: #{c}", ERR_TOOL_FAILURE) unless tool.valid?
          data_values[c] = tool.command_line(!$subcommand_options[:verbose].nil?)
          raw_values[c] = tool.tool_path
          tools << tool
        end
#        data_values.each do |k,v|
#          v = v.join(" ") if v.is_a?(Array)
#          log_notice("data key #{k} value #{v}")
#        end
#        raw_values.each do |k,v|
#          v = v.join(" ") if v.is_a?(Array)
#          log_notice("raw key #{k} value #{v}")
#        end
#        exit
        begin
          pipeline = []
          script.commands.each do |cmd|
            args = MediacastProducer::Common::TemplateArray.substitute(script.arguments[cmd], data_values, '###')
            pipeline << MediacastProducer::Common::TemplateArray.substitute(args, raw_values, '%%%')
          end
          pipeline << arguments unless arguments.empty?
        rescue McastTemplateException => e
          log_crit_and_exit(e.message,e.return_code.to_i)
        end
        cmds = []
        pipeline.each { |args|  cmds << args.join(' ') }
        log_notice(cmds.join(' | '))
#        exit
        return false unless (pids = fork_chain_and_return_pids(*pipeline))
        begin
          puts "<xgrid>\n{control = statusUpdate; percentDone = 0.0; }\n</xgrid>"
          tools.each do |tool|
            next unless tool.respond_to?(:update_status)
            tool.update_status { |percent|
              puts "<xgrid>\n{control = statusUpdate; percentDone = #{percent}; }\n</xgrid>"
            }
          end
          force_quit = false
        rescue SystemExit, Interrupt
          force_quit = true
        end
        result = true
        pids.each do |pid|
          Process.kill('HUP', pid) if force_quit
          pid, status = Process.waitpid2(pid)
          log_notice("pid: #{pid} exit status: #{status.exitstatus}")
          result = false unless status.exited? && status.exitstatus == 0
        end
        puts "<xgrid>\n{control = statusUpdate; percentDone = 100.0; }\n</xgrid>" if result && !force_quit
        return result
      end
    end

    class Preset
      include MediacastProducer::Actions::Base
      include MediacastProducer::Transcoder::Script
      def self.inherited(subclass)
        MediacastProducer::Transcoder.add_preset_class(subclass)
      end

      def name
        self.class.preset_name
      end

      def path
        return @path unless @path.nil?
        @path = preset_for_transcoder(name)
      end

      def preset
        return @preset unless @preset.nil?
        @preset = MediacastProducer::Plist::ScriptPreset.new(path)
      end

      def script
        return @script unless @script.nil?
        @script = preset.script
      end

      def input
        @input
      end

      def output
        @output
      end

      def description
        script.description
      end

      def options_usage
        "usage:  #{name} --prb=PRB --input=INPUT --output=OUTPUT\n" +
        "        [--verbose]  run with verbose output\n"
      end

      def options
        ["input*", "output", "verbose"] + more_options
      end

      def more_options
        return @more_options unless @more_options.nil?
        @more_options = []
        script.options.each do |opt,type|
          @more_options << opt
        end
        @more_options
      end

      def more_options_usage
        "#{script.usage}\n"
      end

      def run(arguments)

        if options.include?("input*")
          require_plural_option(:inputs, 1, 1)
          @input = $subcommand_options[:inputs][0]
        elsif options.include?("input")
          require_option(:input) if options.include?("input")
          @input = $subcommand_options[:input]
        end

        require_option(:output) if options.include?("output")
        @output = $subcommand_options[:output]

        if options.include?("input*") || options.include?("input")
          check_input_and_output_paths_are_not_equal(@input, @output) if options.include?("output")
          check_input_file_exclude_dir(@input)
        end
        check_output_file_exclude_dir(@output) if options.include?("output")

        preset.apply_defaults
        log_crit_and_exit("failed to transcode '#{@input}' to '#{@output}'", -1) unless run_script(arguments)
      end

      include MediacastProducer::ASLClassLogging

    end

    @@preset_classes = []

    def self.add_preset_class(preset_class)
      @@preset_classes << preset_class
    end

    def self.preset_instances
      #      log_notice("fetching preset_instances for #{self.to_s}")
      @@preset_classes.map {|preset_class| preset_class.new }
    end

    def self.options_list
      options_hash = {}
      preset_instances.each do |preset_instance|
        preset_instance.options.each do |option|
          options_hash[option] = true
        end
      end
      options_hash.keys
    end

    def self.load_presets
      preset_list.collect do |preset|
        name = preset.gsub(/[^a-zA-Z0-9_]/,'_').to_s
        class_name = "Transcoder_#{name}"
        Object.const_set(class_name,
        Class::new(Preset) {
          @preset = preset
          def self.preset_name
            @preset
          end
        })
      end
    end

    def self.file_values(f,prefix="")
      values = {}
      values["#{prefix}dirname"] = File.dirname(f)
      values["#{prefix}basename"] = File.basename(f)
      if f =~ /(\.[^\\\/.]+)$/
        values["#{prefix}filename"] = File.basename(f,$1)
        values["#{prefix}extension"] = $1
      else
        values["#{prefix}filename"] = values["#{prefix}basename"]
        values["#{prefix}extension"] = ""
      end
      return values
    end

  end
end

### preset helper methods

def preset_list
  presets = []
  Dir[MCP_LIB + '/mcp/transcoder/presets/*.plist'].each do |path|
    path =~ %r{mcp/transcoder/presets/(.*)\.plist}
    presets << $1
  end
  if $properties["Global Resource Path"]
    Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/Presets/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/Presets/(.*)\.plist}
      presets << $1 unless presets.include?($1)
    end
  end
  if $properties["Workflow Resource Path"]
    Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Presets/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/Presets/(.*)\.plist}
      presets << $1 unless presets.include?($1)
    end
  end
  presets.sort
end

def available_presets
  preset_list.collect do |preset|
    "  #{preset}\n"
  end
end

def require_preset(preset)
  unless preset_list.include? preset
    log_crit_and_exit("specified preset '#{preset}' not found",-1)
  end
end

def preset_for_transcoder(preset)
  if preset =~ /.*\.plist$/ && File.exist?(preset) && !File.directory?(preset)
    path = preset
  else
    require_preset(preset)
    if $properties["Workflow Resource Path"]
      path = "#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Presets/#{preset}.plist"
    end
    unless path && File.exist?(path) && !File.directory?(preset)
      if $properties["Global Resource Path"]
        path = "#{$properties["Global Resource Path"]}/Resources/Transcoder/Presets/#{preset}.plist"
      end
    end
    unless path && File.exist?(path) && !File.directory?(preset)
      path = MCP_LIB + "/mcp/transcoder/presets/#{preset}.plist"
    end
  end
  path
end

### script helper methods

def script_list
  scripts = []
  Dir[MCP_LIB + '/mcp/transcoder/scripts/*.plist'].each do |path|
    path =~ %r{mcp/transcoder/scripts/(.*)\.plist}
    scripts << $1
  end
  if $properties["Global Resource Path"]
    Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/Scripts/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/Scripts/(.*)\.plist}
      scripts << $1 unless scripts.include?($1)
    end
  end
  if $properties["Workflow Resource Path"]
    Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Scripts/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/Scripts/(.*)\.plist}
      scripts << $1 unless scripts.include?($1)
    end
  end
  scripts.sort
end

def available_scripts
  script_list.collect do |script|
    "  #{script}\n"
  end
end

def require_script(script)
  unless script_list.include? script
    log_crit_and_exit("specified script '#{script}' not found",-1)
  end
end

def script_for_transcoder(script)
  if script =~ /.*\.plist$/ && File.exist?(script) && !File.directory?(script)
    path = script
  else
    require_script(script)
    if $properties["Workflow Resource Path"]
      path = "#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Scripts/#{script}.plist"
    end
    unless path && File.exist?(path) && !File.directory?(preset)
      if $properties["Global Resource Path"]
        path = "#{$properties["Global Resource Path"]}/Resources/Transcoder/Scripts/#{script}.plist"
      end
    end
    unless path && File.exist?(path) && !File.directory?(preset)
      path = MCP_LIB + "/mcp/transcoder/scripts/#{script}.plist"
    end
  end
  path
end
