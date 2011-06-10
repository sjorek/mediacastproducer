#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
require 'mcp/propertylist'

module MediacastProducer
  module Encoder
    class Template < MediacastProducer::PropertyList
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

      def sanatize_option(value, type)
        if value == nil
          raise ArgumentError.new, 'invalid value: nil'
        elsif type.downcase == "integer"
          return Integer(value)
        elsif type.downcase == "real"
          return Float(value)
        end
        value
      end

      def sanatize_options(input)
        options.each do |opt,type|
          begin
            yield opt, sanatize_option(input[opt.to_sym], type)
          rescue ArgumentError => e
            log_crit_and_exit("argument '--#{opt}' got an #{e.message}", ERR_INVALID_ARG_TYPE)
          end
        end
      end
    end

  end
end