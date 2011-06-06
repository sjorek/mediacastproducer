#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2008 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'common/pcast_exception'

class McastException < PcastException
end

class McastToolException < McastException
  def initialize(return_code=ERR_TOOL_FAILURE, message=nil)
    super(return_code, message)
  end
end

#require 'client'
#
#class PcastException < RuntimeError
#  attr_reader :return_code
#  
#  def initialize(return_code=nil, message=nil)
#    super(message)
#    @return_code = return_code
#  end
#end
#
#class PListException < PcastException
#  def initialize(return_code=ERR_PLIST_FAILURE, message=nil)
#    super(return_code, message)
#  end  
#end
#
#class PcastCmdException < PcastException
#  attr_reader :cmd_exception
#  
#  def initialize(return_code, cmd_exception=nil, message=nil)
#    super(return_code, message)
#    @cmd_exception = cmd_exception 
#  end
#end
#
#class PcastServerException < PcastException
#  def initialize(return_code, message=nil)
#    super(return_code, message)
#  end
#end
