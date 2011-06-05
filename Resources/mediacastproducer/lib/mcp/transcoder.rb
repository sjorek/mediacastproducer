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

module MediacastProducer
  module Transcoder
  
    @@action_classes = []
    
    def self.add_action_class(action_class)
      @@action_classes << action_class
    end
    
    def self.action_instances
      @@action_classes.map { |action_class| action_class.new }
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
#        log_notice('loading internal transcoder: ' + name.to_s)
        require name
      end
      if $properties["Global Resource Path"]
        Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/*.rb"].each do |path|
          name = File.join(File.dirname(path), File.basename(path, ".rb"))
#          log_notice('loading global transcoder: ' + name.to_s)
          require name
        end
      end
      if $properties["Workflow Resource Path"]
        Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/*.rb"].each do |path|
          name = File.join(File.dirname(path), File.basename(path, ".rb"))
#          log_notice('loading workflow transcoder: ' + name.to_s)
          require name
        end
      end
    end
    
  end
end

### Helper methods

def transcoder_list
  transcoders = []
  Dir[MCP_LIB + '/mcp/transcoder/*/*.rb'].each do |path|
    path =~ %r{mcp/transcoder/(.*/.*)\.rb}
    transcoders << $1
  end
  if $properties["Global Resource Path"]
    Dir["#{$properties["Global Resource Path"]}/Resources/Transcoder/*/*.rb"].each do |path|
      path =~ %r{.*/Resources/Transcoder/(.*/.*)\.rb}
      transcoders << $1 unless transcoders.include?($1)
    end
  end
  if $properties["Workflow Resource Path"]
    Dir["#{$properties["Workflow Resource Path"]}/Resources/Transcoder/*/*.rb"].each do |path|
      path =~ %r{.*/Resources/Transcoder/(.*/.*)\.rb}
      transcoders << $1 unless transcoders.include?($1)
    end
  end
  transcoders.sort
end

def available_transcoders(engine)
  return available_encoders if engine == "pcast"
  transcoder_list.collect do |transcoder|
    "  #{$1}\n" if transcoder =~ /^#{engine}\/(.+)/
  end
end

def require_transcoder(transcoder)
  unless transcoder_list.include? transcoder
    log_crit_and_exit("specified transcoder '#{transcoder}' not found",-1)
  end
end

def action_for_transcoder(transcoder)
  if $properties["Workflow Resource Path"]
    action = "#{$properties["Workflow Resource Path"]}/Resources/Transcoder/#{transcoder}.rb"
  end
  unless action && File.exist?(action)
    if $properties["Global Resource Path"]
      action = "#{$properties["Global Resource Path"]}/Resources/Transcoder/#{transcoder}.rb"
    end
  end
  unless action && File.exist?(action)
    action = MCP_LIB + "/mcp/transcoder/#{transcoder}.rb"
  end
  action
end