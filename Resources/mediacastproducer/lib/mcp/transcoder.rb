#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/actions'
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
    
    def self.load_actions
      Dir[MCP_LIB + '/mcp/transcoder/*.rb'].each do |path|
        name = File.join(File.dirname(path), File.basename(path, ".rb"))
        require name
      end
      if $properties["Global Resource Path"]
        Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/*.rb"].each do |path|
          name = File.join(File.dirname(path), File.basename(path, ".rb"))
          require name
        end
      end
      if $properties["Workflow Resource Path"]
        Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/*.rb"].each do |path|
          name = File.join(File.dirname(path), File.basename(path, ".rb"))
          require name
        end
      end
    end
  end
end

### Helper methods

def preset_list
  presets = []
  Dir[MCP_LIB + '/mcp/transcoder/*/*.plist'].each do |path|
    path =~ %r{mcp/transcoder/(.*/.*)\.plist}
    presets << $1
  end
  if $properties["Global Resource Path"]
    Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/*/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/(.*/.*)\.plist}
      presets << $1 unless presets.include?($1)
    end
  end
  if $properties["Workflow Resource Path"]
    Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/*/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/(.*/.*)\.plist}
      presets << $1 unless presets.include?($1)
    end
  end
  presets.sort
end

def available_presets(engine)
  return available_encoders if engine == "quicktime"
  preset_list.collect do |preset|
    "  #{$1}\n" if preset =~ /^#{engine}\/(.*)/
  end
end

def require_preset(engine, preset)
  unless preset_list.include? "#{engine}/#{preset}"
    log_crit_and_exit("specified preset '#{preset}' not found for engine '#{engine}'",-1)
  end
end

def preset_for_transcoder(engine, preset)
  if preset =~ /.*\.plist$/ && File.exist?(preset) && !File.directory?(preset)
    settings = preset
  else
    if engine == 'quicktime'
      require_encoder(preset)
      settings = settings_for_encoder(preset)
    else
      require_preset(engine, preset)
      if $properties["Workflow Resource Path"]
        settings = "#{$properties["Workflow Resource Path"]}/Resources/Transcoder/#{engine}/#{preset}.plist"
      end
      unless settings && File.exist?(settings)
        if $properties["Global Resource Path"]
          settings = "#{$properties["Global Resource Path"]}/Resources/Transcoder/#{engine}/#{preset}.plist"
        end
      end
      unless settings && File.exist?(settings)
        settings = MCP_LIB + "/mcp/transcoder/#{engine}/#{preset}.plist"
      end
    end
  end
  settings
end
