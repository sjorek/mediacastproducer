#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
require 'mcp/plist/script_template'

module MediacastProducer
  module Plist
    class ScriptPreset < PropertyList
      def defaults
        return @defaults unless @defaults.nil?
        @defaults = data['defaults'].collect
      end

      def script
        return @script unless @script.nil?
        @script = ScriptTemplate.new(script_for_transcoder(data['script']))
      end

      def apply_defaults(input=nil)
        opts = {} unless block_given?
        script.options.each do |opt, type|
          value = (input.nil? || input[opt.to_sym].nil?) ? defaults[opt] : input[opt.to_sym]
          begin
            val = script.sanatize_option(value, type)
          rescue ArgumentError => e
            log_crit_and_exit("argument '--#{opt}' got an #{e.message}", ERR_INVALID_ARG_TYPE)
          end
          yield opt, val if block_given?
          opts[opt] = val unless block_given?
        end
        opts unless block_given?
      end
    end
  end
end