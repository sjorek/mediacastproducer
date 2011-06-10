#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

module MediacastProducer
  module Tools
  
    @@tool_classes = []
    
    def self.add_tool_class(tool_class)
      @@tool_classes << tool_class
    end
    
    def self.tool_instances
      load_tools if @@tool_classes.empty?
      @@tool_classes.map { |tool_class| tool_class.new }
    end
    
    def self.load_tools
      Dir[MCP_LIB + '/mcp/tools/*.rb'].each do |path|
        name = File.join(File.dirname(path), File.basename(path, ".rb"))
        require name
      end
    end
    
  end
end

def tool_with_name(tool_name)
  MediacastProducer::Tools.tool_instances.find {|obj| obj.name == tool_name}
end

