#!/usr/bin/ruby
# encoding: utf-8

require 'fileutils'
require 'tmpdir'
require 'digest/sha1'
require 'mp3conv/command_base'

module MP3Conv
  class FFMpeg < CommandBase
    @@default_bin = "/usr/bin/ffmpeg"
    @@default_in_options = {}
    @@default_out_options = {
        '-acodec' => 'libmp3lame',
        '-ab' => '192k',
        '-ar' => '44100',
        '-ac' => '2',
    }

    attr_reader :in_options, :in_file, :out_options, :out_file

    def initialize(in_file, out_file, settings=nil)
      @in_file = File.expand_path(in_file)
      @out_file = File.expand_path(out_file)

      settings ||= {}
      @bin = settings[:bin] || @@default_bin
      @in_options = @@default_in_options.merge(settings[:in_options] || {})
      @out_options = @@default_out_options.merge(settings[:out_options] || {})
    end

    def cmd
      cmd = []
      cmd << @bin
      cmd << "-y"
      @in_options.each_pair do |k,v|
        cmd << k
        cmd << v
      end
      cmd << "-i"
      cmd << @in_file
      @out_options.each_pair do |k,v|
        cmd << k
        cmd << v
      end
      cmd << tmp_out_file
      array_to_command(cmd)
    end

    def tmp_out_file
      @tmp_out_file ||= Dir.tmpdir + "/mp3conv_" + Digest::SHA1.hexdigest(@in_file) + ".mp3"
    end

    def convert
      # make parent directory
      FileUtils.mkdir_p(File.dirname(@out_file)) 

      # check permit
      if !File.writable?(File.exist?(@out_file) ? @out_file : File.dirname(@out_file))
        raise IOError, "permission denied: #{@out_file}"
      end

      # convert
      _execute(cmd)

      # move
      FileUtils.mv(tmp_out_file, @out_file)

      true
    end
  end
end
