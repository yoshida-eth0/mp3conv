#!/usr/bin/ruby
# encoding: utf-8

require 'rubygems'
$LOAD_PATH << File.expand_path(__FILE__+"/../../lib/")
require 'mp3conv'

MP3Conv::SingleProcess.single_run(
  "/hdd2/mp3conv/mp3conv_input",
  "/hdd2/mp3conv/mp3conv_output",
  {
    :make_output_top_dir => true,
    :running_dir => "/hdd2/mp3conv/mp3conv_running",
    :output_org_dir => "/hdd2/mp3conv/mp3conv_output_org",
    :audio_exts => ['mp3', 'm4a', 'wma', 'wav', 'ogg', 'flac', 'ape'],
    :stdout => STDOUT,
    :ffmpeg => {
      :bin => "/usr/bin/ffmpeg",
      :in_options => {
      },
      :out_options => {
        '-acodec' => 'libmp3lame',
        '-ab' => '192k',
        '-ar' => '44100',
        '-ac' => '2',
      }
    },
    :mp3split => {
      :bin => "/usr/bin/mp3splt",
      :options => {
        "-a" => nil,
        "-f" => nil,
        "-o" => "@n @p - @t",
      },
    },
  }
)
