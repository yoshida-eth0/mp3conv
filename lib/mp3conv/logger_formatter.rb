#!/usr/bin/ruby
# encoding: utf-8

module MP3Conv
  class LoggerFormatter < Logger::Formatter
    attr_accessor :stdout

    def call(severity, time, progname, msg)
      if msg.is_a?(String)
        msg = remove_invalid_bytes(msg)
      end
      msg = super(severity, time, progname, msg)
      msg = msg.gsub(/\n/, "\n    ").gsub(/ +$/, "")
      stdout.write(msg) if stdout
      msg
    end

    def remove_invalid_bytes(msg)
      msg = msg.unpack('C*').map {|b| b==0x0d ? 0x0a : b}.pack('C*').force_encoding("UTF-8")
      #msg = msg.encode("UTF-8", "UTF-8", :invalid => :replace, :undef => :replace, :replace => '?')
      tmp_enc = "CP932"
      msg = msg.encode(tmp_enc, "UTF-8", :invalid => :replace, :undef => :replace, :replace => '?')
      msg = msg.encode("UTF-8", tmp_enc, :invalid => :replace, :undef => :replace, :replace => '?')
    end
  end
end
