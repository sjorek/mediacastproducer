#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#

MCP_CONTRIB_CF_PROPERTY_LIST_LIB = File.join(MCP_RES,'cfpropertylist','lib')
$LOAD_PATH.push(File.expand_path(MCP_CONTRIB_CF_PROPERTY_LIST_LIB)) unless
$LOAD_PATH.include?(MCP_CONTRIB_CF_PROPERTY_LIST_LIB) || $LOAD_PATH.include?(File.expand_path(MCP_CONTRIB_CF_PROPERTY_LIST_LIB))
require 'cfpropertylist'
require 'mcp/common/asl_class_logging'

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

      include MediacastProducer::ASLClassLogging

    end
  end
end