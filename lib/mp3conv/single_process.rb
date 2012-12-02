#!/usr/bin/ruby
# encoding: utf-8

module MP3Conv
  class SingleProcess
    PID_FILE = "/var/run/mp3conv.pid"

    class << self
      def single_run(settings)
        if !running?
          File.open(PID_FILE, "w") {|f| f.write(Process.pid)}
          Job.run_loop(settings)
        end
      end

      def running?
        pid = nil
        if File.exist?(PID_FILE)
          pid = open(PID_FILE, "r") {|f| f.read}.strip.to_i rescue nil
        end

        pid && File.exist?("/proc/#{pid}")
      end
    end
  end
end
