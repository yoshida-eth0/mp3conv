#!/usr/bin/ruby
# encoding: utf-8

require 'open3'
require 'mp3conv/command_error'

module MP3Conv
  class CommandBase
    attr_accessor :logger

    def array_to_command(cmd)
      cmd.map {|x| '"'+x.gsub('"', '\\"').gsub('$', '\\$').gsub('!', '"\'!\'"')+'"'}.join(" ")
    end

    def _execute(cmd)
      if logger
        logger.info("#{self.class.to_s} command: #{cmd}")
      end

      stdout, stderr, status = Open3.capture3(cmd)
      if status.exitstatus==0
        # success log
        if logger
          #if stdout && 0<stdout.length
          #  logger.info("#{self.class.to_s} stdout: #{stdout}")
          #end
          #if stderr && 0<stderr.length
          #  logger.info("#{self.class.to_s} stderr: #{stderr}")
          #end
          logger.info("#{self.class.to_s} exit status: #{status.exitstatus}")
        end
      else
        # failure log
        if logger
          if stdout && 0<stdout.length
            logger.info("#{self.class.to_s} stdout: #{stdout}")
          end
          if stderr && 0<stderr.length
            logger.error("#{self.class.to_s} stderr: #{stderr}")
          end
          logger.error("#{self.class.to_s} exit status: #{status.exitstatus}")
        end

        # exception
        raise CommandError, "exitstatus: #{status.exitstatus}\n#{stderr}"
      end
    end
  end
end
