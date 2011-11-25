#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
require 'mcp/plist/propertylist'

module MediacastProducer
  module Plist
    class ScriptTemplate < PropertyList
      def arguments
        return @arguments unless @arguments.nil?
        @arguments = data['arguments']
      end

      def commands
        return @commands unless @commands.nil?
        @commands = data['commands'].split(',')
      end

      def options
        return @options unless @options.nil?
        @options = data['options']
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

      def sanatize_option(value, cfg)
        if value.nil?
          raise ArgumentError.new, "missing value" if cfg['required']
          return "", ""
        end
        raw = nil
        case cfg['type']
        when "integer"
          raw = Integer(value)
          min = cfg['minimum'] unless cfg['minimum'].nil?
          max = cfg['maximum'] unless cfg['maximum'].nil?
        when "real"
          raw = Float(value)
          min = cfg['minimum'] unless cfg['minimum'].nil?
          max = cfg['maximum'] unless cfg['maximum'].nil?
        when "string"
          raw = String(value)
        else
          raise ArgumentError.new, "unknown type '#{cfg['type']}'"
        end
        raise ArgumentError.new, "value below minimum '#{min}'" unless min.nil? || min <= raw
        raise ArgumentError.new, "value above maximum '#{max}'" unless max.nil? || max >= raw
        raise ArgumentError.new, "invalid value" unless cfg['values'].nil? || cfg['values'].include?(raw)
        raise ArgumentError.new, "invalid format" unless cfg['match'].nil? || raw.to_s =~ /#{cfg['match']}/
        return cfg['template'], raw
      end

      def sanatize_options
        unless block_given?
          data = {}
          values = {}
        end
        options.each do |opt,cfg|
#          log_notice("opt #{opt} required #{cfg['required']}")
          require_option(opt.to_sym) if cfg['required']
          begin
            tpl, raw = sanatize_option($subcommand_options[opt.to_sym], cfg)
          rescue ArgumentError => e
            log_crit_and_exit("#{e.message} for argument '--#{opt}'", ERR_INVALID_ARG_TYPE)
          end
          yield opt, tpl, raw if block_given?
          unless block_given?
            data[opt] = tpl
            values[opt] = raw
          end
        end
        return if block_given?
        return data, values
      end
    end
  end
end