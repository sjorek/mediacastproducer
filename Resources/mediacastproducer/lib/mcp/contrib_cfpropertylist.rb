
# CF_PROPERTY_LIST_LIB = File.join(MCP_RES,'cfpropertylist','lib')
CF_PROPERTY_LIST_LIB = File.join(File.dirname(File.dirname(MCP_RES)),'cfpropertylist','lib')
$LOAD_PATH.push(File.expand_path(CF_PROPERTY_LIST_LIB)) unless 
  $LOAD_PATH.include?(CF_PROPERTY_LIST_LIB) || $LOAD_PATH.include?(File.expand_path(CF_PROPERTY_LIST_LIB))
require 'cfpropertylist'
