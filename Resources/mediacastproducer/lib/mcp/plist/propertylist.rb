#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#

# CONTRIB_CF_PROPERTY_LIST_LIB = File.join(MCP_RES,'cfpropertylist','lib')
CONTRIB_CF_PROPERTY_LIST_LIB = File.join(File.dirname(File.dirname(MCP_RES)),'cfpropertylist','lib')
$LOAD_PATH.push(File.expand_path(CONTRIB_CF_PROPERTY_LIST_LIB)) unless 
  $LOAD_PATH.include?(CONTRIB_CF_PROPERTY_LIST_LIB) || $LOAD_PATH.include?(File.expand_path(CONTRIB_CF_PROPERTY_LIST_LIB))
require 'cfpropertylist'

module MediacastProducer
  module Plist
    class PropertyList
      def initialize(path=nil)
        @file = nil
        @plist = nil
        @data = nil
        load(path) unless path.nil?
      end

      def load(path)
        @file = Pathname.new(path).realpath
        @plist = CFPropertyList::List.new.load(file)
        @data = CFPropertyList.native_types(plist)
      end

      def file
        @file
      end

      def plist
        @plist
      end

      def data
        @data
      end
    end
  end
end