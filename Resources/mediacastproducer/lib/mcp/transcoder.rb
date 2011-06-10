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

### preset helper methods

def preset_list
  presets = []
  Dir[MCP_LIB + '/mcp/transcoder/presets/*/*.plist'].each do |path|
    path =~ %r{mcp/transcoder/presets/(.*/.*)\.plist}
    presets << $1
  end
  if $properties["Global Resource Path"]
    Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/Presets/*/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/Presets/(.*/.*)\.plist}
      presets << $1 unless presets.include?($1)
    end
  end
  if $properties["Workflow Resource Path"]
    Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Presets/*/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/Presets/(.*/.*)\.plist}
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
    path = preset
  else
    if engine == 'quicktime'
      require_encoder(preset)
      path = settings_for_encoder(preset)
    else
      require_preset(engine, preset)
      if $properties["Workflow Resource Path"]
        path = "#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Presets/#{engine}/#{preset}.plist"
      end
      unless path && File.exist?(path)
        if $properties["Global Resource Path"]
          path = "#{$properties["Global Resource Path"]}/Resources/Transcoder/Presets/#{engine}/#{preset}.plist"
        end
      end
      unless path && File.exist?(path)
        path = MCP_LIB + "/mcp/transcoder/presets/#{engine}/#{preset}.plist"
      end
    end
  end
  path
end

### template helper methods

def template_list
  templates = []
  Dir[MCP_LIB + '/mcp/transcoder/templates/*.plist'].each do |path|
    path =~ %r{mcp/transcoder/templates/(.*)\.plist}
    templates << $1
  end
  if $properties["Global Resource Path"]
    Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/Scripts/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/Scripts/(.*)\.plist}
      templates << $1 unless templates.include?($1)
    end
  end
  if $properties["Workflow Resource Path"]
    Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Scripts/*.plist"].each do |path|
      path =~ %r{.*/Resources/Transcoder/Scripts/(.*)\.plist}
      templates << $1 unless templates.include?($1)
    end
  end
  templates.sort
end

def available_templates
  template_list.collect do |template|
    "  #{template}\n"
  end
end

def require_template(template)
  unless template_list.include? template
    log_crit_and_exit("specified template '#{template}' not found",-1)
  end
end

def template_for_transcoder(template)
  if template =~ /.*\.plist$/ && File.exist?(template) && !File.directory?(template)
    path = template
  else
    require_template(template)
    if $properties["Workflow Resource Path"]
      path = "#{$properties["Workflow Resource Path"]}/Resources/Transcoder/Scripts/#{template}.plist"
    end
    unless path && File.exist?(path)
      if $properties["Global Resource Path"]
        path = "#{$properties["Global Resource Path"]}/Resources/Transcoder/Scripts/#{template}.plist"
      end
    end
    unless path && File.exist?(path)
      path = MCP_LIB + "/mcp/transcoder/templates/#{template}.plist"
    end
  end
  path
end
