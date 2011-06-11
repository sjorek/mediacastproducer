#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
require 'mcp/plist/propertylist'

module MediacastProducer
  module Plist
    class Template < PropertyList
      def arguments
        return @arguments unless @arguments.nil?
        @arguments = data['arguments'].collect
      end

      def commands
        return @commands unless @commands.nil?
        @commands = data['commands'].split(',')
      end

      def options
        return @options unless @options.nil?
        @options = data['options'].collect
      end

      def usage
        return @usage unless @usage.nil?
        @usage = data['usage']
      end

      def sanatize_option(value, type)
        # log_notice("sanatizing '#{value}' for type #{type}")
        if value == nil
          raise ArgumentError.new, 'invalid or missing value'
        elsif type.downcase == "integer"
          return Integer(value)
        elsif type.downcase == "real"
          return Float(value)
        end
        value
      end

      def sanatize_options(required=true)
        opts = {}
        options.each do |opt,type|
          require_option(opt.to_sym) if required
          begin
            val = sanatize_option($subcommand_options[opt.to_sym], type)
          rescue ArgumentError => e
            log_crit_and_exit("argument '--#{opt}' got an #{e.message}", ERR_INVALID_ARG_TYPE)
          end
          # log_notice("yield '#{val}' for option #{opt}") if block_given?
          yield opt, val if block_given?
          opts[opt] = val unless block_given?
        end
        opts unless block_given?
      end

    end

  end
end