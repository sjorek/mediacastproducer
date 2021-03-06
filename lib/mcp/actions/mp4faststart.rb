#  
#  Copyright (c) 2011 Stephan Jorek.  All Rights Reserved.
#  Copyright (c) 2006-2010 Apple Inc.  All Rights Reserved.
#
#  IMPORTANT NOTE:  This file is licensed only for use on Apple-labeled computers 
#  and is subject to the terms and conditions of the Apple Software License Agreement 
#  accompanying the package this file is a part of.  You may not port this file to 
#  another platform without Apple's written consent.
#

require 'mcp/actions/base'
require 'mcp/qt/qt'

module PodcastProducer
  module Actions

    class MP4Faststart < Base
      def command
        return @command unless @command.nil?
        c = tool_with_name(name)
        @command = c.valid? unless c.nil?
      end
      def usage
        "#{name}: optimize Mp4-alike (incl. Quicktime) or for streaming\n\n" +
        "usage: #{name} --prb=PRB --input=INPUT\n"+
        "                [--output=OUTPUT]  write to OUTPUT, otherwise work in place on INPUT\n" +
        "                [--streamable]     test and exits accordingly with 0 or 1; e.g.:\n" +
        "                                   ... && echo true || echo false\n"
      end
      def options
        ["input*", "streamable", "output"]
      end
      def run(arguments)
        
        require_plural_option(:inputs, 1, 1)
        
        input = $subcommand_options[:inputs][0]
        output = $subcommand_options[:output]
        
        movie_type = McastQT.info(input,'movieType')
        log_notice('movie type: ' + movie_type.to_s)
        log_crit_and_exit("missing movie type", ERR_MISSING_MOVIETYPE) if movie_type.nil?
        
        is_streamable = McastQT.is_streamable?(input)
        log_notice("is streamable: " + is_streamable.to_s)
        log_crit_and_exit("FINISH", (is_streamable ? 0 : 1)) if $subcommand_options[:streamable]
        
        begin
          output = McastQT.verify_input_and_output_paths_are_not_equal(input, output) if output
        rescue PcastException => e
          log_crit_and_exit(e.message, e.return_code.to_i)
        rescue Exception => e
          log_crit_and_exit(e.message, 1)
        end
        if is_streamable
          if output
            log_notice('faststart not necessary, copying INPUT to OUTPUT')
            FileUtils.cp(input , output)
          else
            log_crit_and_exit("skipped editing in place, input is already streamable", ERR_ALLREADY_STREAMABLE)
            return
          end
        else
          log_crit_and_exit("failed to setup tools: #{name}", -1) if command.nil?
          log_notice('faststart optimization for streaming')
          exec_args = [input]
          exec_args << output if output
          command.run(*exec_args)
        end
        FileUtils.chmod_R(0644, output) if output
      end
    end
    
  end
end
