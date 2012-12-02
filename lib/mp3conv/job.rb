#!/usr/bin/ruby
# encoding: utf-8

require 'fileutils'
require 'find'
require 'mp3conv/logger_formatter'

module MP3Conv
  class Job
    @@default_settings = {
      :input_base => nil,
      :running_base => nil,
      :output_base => nil,
      :output_org_base => nil,
      :audio_exts => ['mp3', 'wav', 'ogg', 'flac', 'ape'],
      :stdout => nil,
      :ffmpeg => {},
      :mp3split => {},
    }

    def initialize(basename, settings)
      @basename = basename.sub(/^\//, "").sub(/\/$/, "")
      @settings = @@default_settings.merge(settings || {})
      @ffmpeg_settings = @settings.delete(:ffmpeg)
      @mp3split_settings = @settings.delete(:mp3split)
    end

    def start
      begin
        logger.info("===== start job: #{@basename} =====")

        # move
        logger.info("mv input => running: #{input_dir}")
        FileUtils.mv(input_dir, running_dir)

        # convert audio
        logger.info("=== start convert audio ===")
        logger.info("src audio files: \n#{src_audio_files.join("\n")}".strip)
        src_audio_files.each do |src_file|
          begin
            logger.info("convert start: #{src_file}")
            dst_file = src_file.sub(/\.(#{@settings[:audio_exts].join('|')})$/i, ".mp3")
            ff = FFMpeg.new("#{running_dir}/#{src_file}", "#{output_dir}/#{dst_file}", @ffmpeg_settings)
            ff.logger = logger
            ff.convert
            logger.info("convert done")
          rescue StandardError => e
            logger.error(e)
          end
        end
        logger.info("=== finish convert audio ===")

        # convert cue
        logger.info("=== start split cue ===")
        logger.info("src cue files: \n#{src_cue_files.join("\n")}".strip)
        src_cue_files.each do |cue_file|
          cue = Cue.new("#{running_dir}/#{cue_file}")
          begin
            logger.info("convert start: #{cue_file}")
            audio_basename = cue.audio_name

            audio_basename = audio_basename.sub(/\.(#{@settings[:audio_exts].join('|')})$/i, ".mp3")
            audio_dirname = File.dirname("#{output_dir}/#{cue_file}")

            sp = MP3Split.new(cue.file_path, "#{audio_dirname}/#{audio_basename}", "#{output_dir}/#{cue_file}", @mp3split_settings)
            sp.logger = logger
            sp.convert

            logger.info("convert done")
          rescue StandardError => e
            logger.error(e)
          ensure
            cue.unlink
          end
        end
        logger.info("=== finish split cue ===")

      rescue StandardError => e
        # write error log
        logger.error(e)

      ensure
        # move
        logger.info("mv running => output_org")
        FileUtils.mv(running_dir, output_org_dir)

        logger.info("===== finish job =====\n")
      end
    end

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
      Find.find(running_dir) {|f|
        if !f.match(/\/\./) && f.match(/\.(#{@settings[:audio_exts].join('|')})$/i)
          files << f.sub(running_dir, "").sub(/^\//, "")
        end
      }
      files.sort
    end

    def src_cue_files
      files = []
      Find.find(running_dir) {|f|
        if !f.match(/\/\./) && f.match(/\.cue$/i)
          files << f.sub(running_dir, "").sub(/^\//, "")
        end
      }
      files.sort
    end

    def input_dir
      @settings[:input_base] + "/" + @basename
    end

    def running_dir
      @settings[:running_base] + "/" + @basename
    end

    def output_dir
      @settings[:output_base] + "/" + @basename
    end

    def output_org_dir
      @settings[:output_org_base] + "/" + @basename
    end

    class << self
      def any_name(settings)
        Dir.entries(settings[:input_base]).each {|f|
          return f unless f.match(/^\./)
        }
        nil
      end

      def run_loop(settings)
        loop {
          name = any_name(settings)
          break unless name

          new(name, settings).start
          sleep(5)
        }
      end
    end
  end
end
