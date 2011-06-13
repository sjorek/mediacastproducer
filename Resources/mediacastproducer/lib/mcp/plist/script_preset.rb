#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
require 'mcp/plist/script_template'

module MediacastProducer
  module Plist
    class ScriptPreset < PropertyList
      def defaults
        return @defaults unless @defaults.nil?
        @defaults = {}
        data['defaults'].collect do |opt,val|
          @defaults[opt.to_s] = val.to_s
        end
        @defaults
      end

      def script
        return @script unless @script.nil?
        @script = ScriptTemplate.new(script_for_transcoder(data['script']))
      end

      def apply_defaults
        defaults.each do |opt,val|
          log_notice("applying #{opt}'s default value: #{val}")
          next if script.options[opt].nil? || !$subcommand_options[opt.to_sym].nil?
          $subcommand_options[opt.to_sym] = val
        end
      end
    end
  end
end