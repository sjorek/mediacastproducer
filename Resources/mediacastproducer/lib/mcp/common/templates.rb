#
# Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
# Adopted from: http://freshmeat.net/articles/templates-in-ruby
#
# Template: Implements a string substituation template.
#
# The template should look like this:
#
# 'Hi ###name###, how are you doing ###time###'
#
# With this template value, you could use the set method to set
# the values "name" and "time" with their appropriate replacement
# values.

# This version of the template class takes either a hash for values,
# or a method or function.  The function takes a single parameter,
# which is the key, and returns a single value, which is the string to
# be used as a replacement.

require 'mcp/common/mcast_exception'

module MediacastProducer
  module Common
    class TemplateString
      # Construct the template object with the template and the
      # replacement values.  "values" can be a hash, a function,
      # or a method.
      def initialize(template, values=nil, replace_str = nil)
        @template = template.clone()
        @replace_strs = {}
        set(replace_str, values) unless values.nil? && replace_str.nil?
      end

      # Set up a replacement set.
      #
      # replace_str: The string that starts and ends a replacement
      # item. For example, "###" would mean that the replacement tokens
      # look like  ###name###.
      #
      # values: The hash of values to replace the replacement token with,
      # or a method to call with a key.
      def set(replace_str, values)
        if values.kind_of?( Hash )
          @replace_strs[ replace_str ] = values.method( :fetch )
        else
          @replace_strs[ replace_str ] = values.clone()
        end
      end

      # Run the template with the given parameters and return
      # the template with the values replaced
      def run()
        out_str = @template.clone()
        @replace_strs.keys.each { |replace_str|
          out_str.gsub!( /#{replace_str}(.*?)#{replace_str}/ ) {
            begin
              val = @replace_strs[ replace_str ].call( $1 )
            rescue IndexError => e
              raise McastTemplateException.new, "Unknown key '#{$1}' found in template"
            end
            val.to_s
          }
        }
        out_str
      end

      # A synonym for run so that you can simply print the class
      # and get the template result
      def to_s() run(); end

      # A class method for direct calls
      # returns in_str with values substituted
      def self.substitute(in_str, values, replace_str='###')
        self.new(in_str, values, replace_str).to_s
      end
    end

    class TemplateArray
      # Construct the template object with the template and the
      # replacement values.  "values" can be a hash, a function,
      # or a method.
      def initialize(template, values=nil, replace_str = nil)
        @template = template.clone()
        @replace_strs = {}
        set(replace_str, values) unless values.nil? && replace_str.nil?
      end

      # Set up a replacement set.
      #
      # replace_str: The string that starts and ends a replacement
      # item. For example, "###" would mean that the replacement tokens
      # look like  ###name###.
      #
      # values: The hash of values to replace the replacement token with,
      # or a method to call with a key.
      def set(replace_str, values)
        if values.kind_of?( Hash )
          @replace_strs[ replace_str ] = values.method( :fetch )
        else
          @replace_strs[ replace_str ] = values.clone()
        end
      end

      # Run the template with the given parameters and return
      # the template with the values replaced
      def run()
        out_arr = []
        @replace_strs.keys.each { |replace_str|
          @template.each do |out_str|
            next if out_str.nil?
            val = nil
            out_str.gsub!( /#{replace_str}(.*?)#{replace_str}/ ) {
              begin
                val = @replace_strs[ replace_str ].call( $1 )
              rescue IndexError => e
                raise McastTemplateException.new, "Unknown key '#{$1}' found in template"
              end
              if val.is_a?(Array)
                val.shift.to_s
              else
                val.to_s
              end
            }
            out_arr << out_str
            if val.is_a?(Array)
              val.each do |out_str|
                out_arr << TemplateString.substitute(out_str, @replace_strs[ replace_str ], replace_str)
              end
            end
          end
        }
        out_arr
      end

      # A synonym for run so that you can simply print the class
      # and get the template result
      def to_s() run.join(' '); end

      # A class method for direct calls
      # returns in_arr with values substituted
      def self.substitute(in_arr, values, replace_str='###')
        self.new(in_arr, values, replace_str).run
      end
    end
  end
end
