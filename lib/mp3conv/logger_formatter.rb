#!/usr/bin/ruby
# encoding: utf-8

module MP3Conv
  class LoggerFormatter < Logger::Formatter
    attr_accessor :stdout

    def call(severity, time, progname, msg)
      msg = super(severity, time, progname, msg)

      msg.force_encoding("ASCII-8BIT")
      msg.gsub!(/[^\r\n]*\r/, "")
      msg = msg.gsub(/\n/, "\n    ").gsub(/ +$/, "")

      stdout.write(msg) if stdout
      msg
    end

  end
end
