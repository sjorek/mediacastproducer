#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
require 'mcp/encoder/template'

module MediacastProducer
  module Encoder
    class Preset < MediacastProducer::PropertyList
      def defaults
        return @defaults unless @defaults.nil?
        @defaults = data['defaults'].collect
      end

      def extensions
        return @extensions unless @extensions.nil?
        @extensions = data['extensions'].split(',')
      end

      def mimetype
        return @mimetype unless @mimetype.nil?
        @mimetype = data['mimetype']
      end

      def template
        return @template unless @template.nil?
        @template = Template.new(template_for_transcoder(data['template']))
      end

      def apply_defaults(input=nil)
        template.options.each do |opt, type|
          value = (input.nil? || input[opt.to_sym].nil?) ? defaults[opt] : input[opt.to_sym]
          begin
            yield opt, template.sanatize_option(value, type)
          rescue ArgumentError => e
            log_crit_and_exit("argument '--#{opt}' got an #{e.message}", ERR_INVALID_ARG_TYPE)
          end
        end
      end
    end
  end
end