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

module MediacastProducer
  module Misc
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
            puts $1
            val = @replace_strs[ replace_str ].call( $1 )
            raise McastTemplateException.new, "Key '#{$1}' found in template but the value has not been set" if val.nil?
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
  end
end
