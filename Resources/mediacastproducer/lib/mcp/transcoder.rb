#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/common/mcast_exception'

module MediacastProducer
  module Transcoder
  
    @@action_classes = []
    
    def self.add_action_class(action_class)
      @@action_classes << action_class
    end
    
    def self.action_instances
#      log_notice("fetching action_instances for #{self.to_s}")
      @@action_classes.map {|action_class| action_class.new }
    end
    
    def self.options_list
      options_hash = {}
      action_instances.each do |action_instance|
        action_instance.options.each do |option|
          options_hash[option] = true
        end
      end
      options_hash.keys
    end
    
    def self.load_scripts
      Dir[MCP_LIB + '/mcp/transcoder/scripts/*.plist'].each do |path|
        name = File.join(File.dirname(path), File.basename(path, ".plist"))
        require name
      end
      if $properties["Global Resource Path"]
        Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/Scripts/*.plist"].each do |path|
          name = File.join(File.dirname(path), File.basename(path, ".plist"))
          require name
        end
      end
      if $properties["Workflow Resource Path"]
        Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Scripts/*.plist"].each do |path|
          name = File.join(File.dirname(path), File.basename(path, ".plist"))
          require name
        end
      end
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

def require_preset(engine, preset)
  unless preset_list.include? "#{engine}/#{preset}"
    log_crit_and_exit("specified preset '#{preset}' not found for engine '#{engine}'",-1)
  end
end

def preset_for_transcoder(engine, preset)
  if preset =~ /.*\.plist$/ && File.exist?(preset) && !File.directory?(preset)
    path = preset
  else
    if engine == 'quicktime'
      require_encoder(preset)
      path = settings_for_encoder(preset)
    else
      require_preset(engine, preset)
      if $properties["Workflow Resource Path"]
        path = "#{$properties["Workflow Resource Path"]}/Resources/Transcoder/#{engine}/#{preset}.plist"
      end
      unless path && File.exist?(path)
        if $properties["Global Resource Path"]
          path = "#{$properties["Global Resource Path"]}/Resources/Transcoder/#{engine}/#{preset}.plist"
        end
      end
      unless path && File.exist?(path)
        path = MCP_LIB + "/mcp/transcoder/#{engine}/#{preset}.plist"
      end
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
    unless path && File.exist?(path)
      if $properties["Global Resource Path"]
        path = "#{$properties["Global Resource Path"]}/Resources/Transcoder/Scripts/#{script}.plist"
      end
    end
    unless path && File.exist?(path)
      path = MCP_LIB + "/mcp/transcoder/scripts/#{script}.plist"
    end
  end
  path
end
