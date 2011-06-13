#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
require 'mcp/plist/propertylist'

module MediacastProducer
  module Plist
    class ScriptTemplate < PropertyList
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
        @options = {}
        data['options'].collect do |opt,type|
          @options[opt.to_s] = type.to_s
        end
        @options
      end

      def extensions
        return @extensions unless @extensions.nil?
        @extensions = data['extensions'].split(',')
      end

      def mimetype
        return @mimetype unless @mimetype.nil?
        @mimetype = data['mimetype'].chomp!
      end

      def description
        return @description unless @description.nil?
        @description = data['description'].chomp!
      end

      def usage
        return @usage unless @usage.nil?
        @usage = data['usage'].chomp!
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
        opts = {} unless block_given?
        options.each do |opt,type|
          require_option(opt.to_sym) if required
          begin
            val = sanatize_option($subcommand_options[opt.to_sym], type)
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