#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#
require 'mcp/contrib/plists'

module MediacastProducer
  class PropertyList
    def initialize(path=nil)
      @path = nil
      @plist = nil
      @data = nil
      load(path) unless path.nil?
    end

    def load(path)
      @path = Pathname.new(path).realpath
      @plist = CFPropertyList::List.new.load(path)
      @data = CFPropertyList.native_types(plist)
    end

    def path
      @path
    end

    def plist
      @plist
    end

    def data
      @data
    end
  end
end