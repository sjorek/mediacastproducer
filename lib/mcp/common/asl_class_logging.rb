module MediacastProducer
  module ASLClassLogging
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