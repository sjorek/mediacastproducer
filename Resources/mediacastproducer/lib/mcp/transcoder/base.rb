#
#  Copyright (c) 2006-2008 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
#  and is subject to the terms and conditions of the Apple Software License Agreement
#  accompanying the package this file is a part of.  You may not port this file to
#  another platform without Apple's written consent.
#

require 'mcp/transcoder'

module MediacastProducer
  module Transcoder
      
    class Base
      
      def self.inherited(subclass)
        MediacastProducer::Transcoder.add_action_class(subclass)
      end
      
      def name
        self.class.name.split("::").last.downcase
      end
      
      def usage
        "usage"
      end
      
      def options
        []
      end
      
      def log_crit(msg)
        ASLLogger.crit(self.class.to_s + ": " + msg)
      end
      
      def log_error(msg)
        ASLLogger.error(self.class.to_s + ": " + msg)
      end
      
      def log_warn(msg)
        ASLLogger.warn(self.class.to_s + ": " + msg)
      end
      
      def log_notice(msg)
        ASLLogger.notice(self.class.to_s + ": " + msg)
      end
      
      def log_info(msg)
        ASLLogger.info(self.class.to_s + ": " + msg)
      end
      
      def log_debug(msg)
        ASLLogger.debug(self.class.to_s + ": " + msg)
      end
      
      def log_crit_and_exit(msg, status_code = -1)
        ASLLogger.crit(self.class.to_s + ": " + msg)
        if $no_fail
          ASLLogger.notice(self.class.to_s + ": " + "No fail flag was set. Exiting with exit code '0'.")
          exit(0)
        else
          exit(status_code)
        end
      end
      
    end

  end
end