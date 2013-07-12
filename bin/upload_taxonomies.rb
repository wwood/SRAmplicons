#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'csv'

# Require the sramplicons database
require '../config/application'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = 'sramplicons'

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
}
o = OptionParser.new do |opts|
  opts.banner = "
    Usage: #{SCRIPT_NAME} taxonomy_file

    Upload the taxonomy in the taxonomy file to the SRAmplicons database \n"

  # logger options
  opts.separator "\nVerbosity:\n\n"
  opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") do |q|
    Bio::Log::CLI.trace('error')
  end
  opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") do | name |
    options[:logger] = name
  end
  opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG") do | s |
    Bio::Log::CLI.trace(s)
  end
end
o.parse!

if ARGV.length != 1
  $stderr.puts o
  exit 1
end

# Setup logging
Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)

log.info "Starting SRAmplicons.."
Sramplicons::Application.initialize!

p Cluster.first
