#!/usr/bin/ruby
# encondig: utf-8

require 'fileutils'
require 'mp3conv/command_base'

module MP3Conv
  class MP3Split < CommandBase
    @@bin = "/usr/bin/mp3splt"
    @@default_options = {
      "-a" => nil,
      "-f" => nil,
      "-o" => "@n @p - @t",
    }

    def initialize(cue_file, src_file, dst_dir, settings=nil)
      @cue_file = cue_file
      @src_file = src_file
      @dst_dir = dst_dir

      settings ||= {}
      @bin = settings[:bin] || @@bin
      @options = @@default_options.merge(settings[:options] || {})
    end

    def cmd
      cmd = []
      cmd << @bin
      @options.each_pair do |k,v|
        cmd << k
        cmd << v if v
      end
      cmd << "-d"
      cmd << @dst_dir
      cmd << "-c"
      cmd << @cue_file
      cmd << @src_file
      array_to_command(cmd)
    end

    def convert
      # make dst dir
      FileUtils.mkdir_p(@dst_dir) 

      # check permit
      if !File.writable?(@dst_dir)
        raise IOError, "permission denied: #{@dst_file}"
      end

      # convert
      _execute(cmd)
    end
  end
end
