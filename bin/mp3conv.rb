#!/usr/bin/ruby
# encoding: utf-8

require 'rubygems'
$LOAD_PATH << File.expand_path(__FILE__+"/../../lib/")
require 'mp3conv'

# usage
if ARGV.length==0 || ARGV[0]=="-h" || ARGV[0]=="--help"
  puts "Usage: #{File.basename($0)} input_dir [output_dir]"
  exit 1
end

# args
input_dir = ARGV[0]
output_dir = ARGV[1]
make_output_top_dir = true
unless output_dir
  output_dir = input_dir + "/mp3conv_output"
  make_output_top_dir = false
end

# check input
unless File.exist?(input_dir)
  puts "input dir is not found: #{input_dir}"
  exit 1
end

# run
MP3Conv::Job.new(
  input_dir,
  output_dir,
  {
    :make_output_top_dir => make_output_top_dir,
    :running_dir => nil,
    :output_org_dir => nil,
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
).run
