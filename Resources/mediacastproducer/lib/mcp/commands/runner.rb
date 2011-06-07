#
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2004 Steven Kah Hien Wong.  All Rights Reserved.
#

module MediacastProducer
  module Commands
    class Runner
      attr :command
      attr :childPid
      def initialize(*command)
        @command       = command
        @childPid      = nil
        @waitingThread = nil

        @readPipe      = nil
        @readErrorPipe = nil
        @writePipe     = nil
      end

      def closeWrite
        @writePipe.close
      end

      def kill
        Process.kill("KILL", @childPid)
      end

      def read
        return @readPipe.read
      end

      def readError
        return @readErrorPipe.read
      end

      def run
        parent_to_child_read, parent_to_child_write             = IO.pipe
        child_to_parent_read, child_to_parent_write             = IO.pipe
        child_to_parent_error_read, child_to_parent_error_write = IO.pipe

        @childPid = fork do
          parent_to_child_write.close
          child_to_parent_read.close
          child_to_parent_error_read.close

          $stdin.reopen(parent_to_child_read) or
          raise "Unable to redirect STDIN"
          $stdout.reopen(child_to_parent_write) or
          raise "Unable to redirect STDOUT"
          $stderr.reopen(child_to_parent_error_write) or
          raise "Unable to redirect STDERR"

          # Wait until parent is ready before we start doing anything
          if parent_to_child_read.readchar.chr != "R"
            raise "Unexpected input from parent"
          end

          exec(*@command)
        end

        if @childPid
          @waitingThread = Thread.new do
            return_code = -1
  
            begin
              return_code = Process.waitpid2(@childPid)
            rescue SystemError
              raise "Process finished running already!"
            end
            return_code = return_code[1].exitstatus
  
            return_code
          end
        end

        child_to_parent_write.close
        child_to_parent_error_write.close
        parent_to_child_read.close

        return nil unless @childPid

        @readPipe      = child_to_parent_read
        @readErrorPipe = child_to_parent_error_read
        @writePipe     = parent_to_child_write

        # Tell child we are ready
        @writePipe.write("R")
        @writePipe.flush

        @childPid
      end

      #--------------------------------------------------------------------------
      # Description: Waits for command to exit
      # Returns    : The return code of the program when it exited
      #--------------------------------------------------------------------------
      def wait
        if not @childPid or not @waitingThread
          raise "Waiting for a process that has not started"
        end

        return_value = @waitingThread.value

        @waitingThread = nil
        @childPid = nil

        return return_value
      end

      def write(string)
        if not @childPid or not @waitingThread
          raise "Writing to a process that has not started"
        end

        @writePipe.write(string)
      end

      def self.fork_exec_and_wait(*command)
        cmd = self.new(*command)
        cmd.wait unless cmd.run
      end

      def self.fork_exec_and_wait_for_success(*command)
        self.fork_exec_and_wait(*command) == 0
      end
    end
  end
end