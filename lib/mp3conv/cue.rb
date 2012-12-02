#!/usr/bin/ruby
# encoding: utf-8

require 'tmpdir'
require 'digest/sha1'

module MP3Conv
  class Cue
    def initialize(cue_file)
      @cue_file = cue_file
      @cue_txt = nil
      @tmpfile = nil
    end

    def make_utf8_cue_file
      return if @tmpfile

      @tmpfile = open(file_path, "w+")
      txt = open(@cue_file, "r") {|f| f.read}

      enc_arr = ["CP932", "euc-jp-ms", "GB18030", "UTF-8"]
      enc_arr.each do |enc|
        begin
          @cue_txt = txt.encode("UTF-8", enc)
          @tmpfile.write(@cue_txt)
          @tmpfile.close
          return
        rescue StandardError => e
        end
      end
      raise "cue encoding error: text decode error"
    end

    def audio_name
      make_utf8_cue_file

      lines = @cue_txt.split(/[\r\n]+/)
      lines.each do |line|
        m = line.match(/^FILE\s+("[^"]+"|[^" ]+)/)
        return m[1].sub(/^"(.+)"$/, '\1') if m
      end
      raise "cue file error: FILE syntax is not found"
    end

    def file_path
      @file_path ||= Dir.tmpdir + "/mp3conv_" + Digest::SHA1.hexdigest(@cue_file) + ".cue"
    end

    def unlink
      File.unlink(file_path) rescue nil
    end
  end
end
