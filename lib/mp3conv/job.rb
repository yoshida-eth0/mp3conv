#!/usr/bin/ruby
# encoding: utf-8

require 'fileutils'
require 'find'
require 'yaml'
require 'mp3conv/logger_formatter'

module MP3Conv
  class Job
    @@default_settings = {
      :make_output_top_dir => true,
      :running_dir => nil,
      :output_org_dir => nil,
      :audio_exts => ['mp3', 'm4a', 'wma', 'wav', 'ogg', 'flac', 'ape'],
      :stdout => nil,
      :ffmpeg => {},
      :mp3split => {},
    }

    attr_reader :input_dir, :output_dir

    def initialize(input_dir, output_dir, settings)
      @input_dir = input_dir.sub(/\/$/, "")
      @output_dir = output_dir.sub(/\/$/, "")

      @settings = @@default_settings.merge(settings || {})
      @ffmpeg_settings = @settings.delete(:ffmpeg)
      @mp3split_settings = @settings.delete(:mp3split)

      if @settings[:make_output_top_dir]
        @output_dir += "/" + basename
      end
    end


    # action

    def run
      begin
        # job info
        logger.info("===== start job =====\n" + YAML::dump({
          :input_dir => input_dir,
          :output_dir =>  output_dir,
          :running_dir => running_dir,
          :output_org_dir => output_org_dir,
          :audio_exts => @settings[:audio_exts],
          :ffmpeg_settings => @ffmpeg_settings,
          :mp3split_settings => @mp3split_settings,
        }).strip)

        # before action
        before_action

        # convert audio
        logger.info("=== start convert audio ===")
        logger.info("src audio files: \n#{src_audio_files.join("\n")}".strip)
        src_audio_files.each do |src_file|
          begin
            exec_ffmpeg(src_file)
          rescue StandardError => e
            logger.error(e)
          end
        end
        logger.info("=== finish convert audio ===")

        # convert cue
        logger.info("=== start split cue ===")
        logger.info("src cue files: \n#{src_cue_files.join("\n")}".strip)
        src_cue_files.each do |cue_file|
          begin
            exec_mp3split(cue_file)
          rescue StandardError => e
            logger.error(e)
          end
        end
        logger.info("=== finish split cue ===")

      rescue StandardError => e
        # write error log
        logger.error(e)

      ensure
        # after action
        after_action

        logger.info("===== finish job =====\n")
      end
    end

    def before_action
      if running_dir
        # move to running dir
        logger.info("mv input => running")
        FileUtils.mv(input_dir, running_dir)
      end
    end

    def after_action
      # move
      if output_org_dir
        if running_dir
          logger.info("mv running => output_org")
          FileUtils.mv(running_dir, output_org_dir)
        else
          logger.info("mv input => output_org")
          FileUtils.mv(input_dir, output_org_dir)
        end
      elsif running_dir
        logger.info("mv running => input")
        FileUtils.mv(running_dir, input_dir)
      end
    end

    def exec_ffmpeg(src_file)
      logger.info("convert start: #{src_file}")

      _input_dir = running_dir || input_dir
      dst_file = src_file.sub(/\.(#{@settings[:audio_exts].join('|')})$/i, ".mp3")

      ff = FFMpeg.new("#{_input_dir}/#{src_file}", "#{output_dir}/#{dst_file}", @ffmpeg_settings)
      ff.logger = logger
      ff.convert

      logger.info("convert done")
    end

    def exec_mp3split(cue_file)
      cue = nil
      begin
        logger.info("convert start: #{cue_file}")

        _input_dir = running_dir || input_dir
        cue = Cue.new("#{_input_dir}/#{cue_file}")

        audio_basename = cue.audio_name
        audio_basename = audio_basename.sub(/\.(#{@settings[:audio_exts].join('|')})$/i, ".mp3")

        audio_dirname = File.dirname("#{output_dir}/#{cue_file}")

        sp = MP3Split.new(cue.file_path, "#{audio_dirname}/#{audio_basename}", "#{output_dir}/#{cue_file}", @mp3split_settings)
        sp.logger = logger
        sp.convert

        logger.info("convert done")
      ensure
        if cue
          cue.unlink
        end
      end
    end


    # getter

    def logger
      @logger ||= Proc.new {
        # make output dir
        FileUtils.mkdir_p(output_dir)

        logger = Logger.new("#{output_dir}/mp3conv.log")
        logger.formatter = LoggerFormatter.new
        logger.formatter.stdout = @settings[:stdout]
        logger
      }.call
    end

    def src_audio_files
      files = []
      _input_dir = running_dir || input_dir
      Find.find(_input_dir) {|f|
        if !f.match(/\/\./) && f.match(/\.(#{@settings[:audio_exts].join('|')})$/i)
          f = f.sub(_input_dir, "").sub(/^\//, "")
          files << f
        end
      }
      files.sort
    end

    def src_cue_files
      files = []
      _input_dir = running_dir || input_dir
      Find.find(_input_dir) {|f|
        if !f.match(/\/\./) && f.match(/\.cue$/i)
          files << f.sub(running_dir, "").sub(/^\//, "")
        end
      }
      files.sort
    end

    def basename
      File.basename(@input_dir)
    end

    def running_dir
      @settings[:running_dir] ? (@settings[:running_dir] + "/" + basename) : nil
    end

    def output_org_dir
      @settings[:output_org_dir] ? (@settings[:output_org_dir] + "/" + basename) : nil
    end


    # class method

    class << self
      def any_name(input_dir)
        Dir.entries(input_dir).each {|f|
          if !f.match(/^\./) && !@@dones.include?(f)
            return f
          end
        }
        nil
      end

      def run_loop(input_dir, output_dir, settings)
        @@dones ||= []
        loop {
          name = any_name(input_dir)
          break unless name

          new("#{input_dir}/#{name}", output_dir, settings).run
          @@dones << name
          sleep(5)
        }
      end
    end
  end
end
