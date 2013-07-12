#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'csv'
require 'tempfile'
require 'systemu'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = 'sramplicons'

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
}
o = OptionParser.new do |opts|
  opts.banner = "
    Usage: #{SCRIPT_NAME} -t taxonomy_file -d database_file

    Upload the taxonomy in the taxonomy file to the SRAmplicons database \n"


  opts.on('-t','--taxonomy PATH', 'Path the to taxonomy file, which contains one line per taxonomy, with ID first, then tab-separated taxonomy information') do |arg|
    options[:taxonomy_path] = arg
  end
  opts.on('-d','--db PATH', 'Path the to sramplicons sqlite3 database file') do |arg|
    options[:database_path] = arg
  end

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

if ARGV.length != 0 or options[:database_path].nil? or options[:taxonomy_path].nil?
  $stderr.puts o
  exit 1
end

# Setup logging
Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)


Tempfile.open('tax_data') do |tempfile|
  log.info "Creating CSV file for upload.."
  primary_key = 1
  header = true
  CSV.foreach(options[:taxonomy_path],:col_sep => "\t") do |row|
    raise "Unexpected line found: #{row.inspect}" unless row.length > 1
    if header
      header = false
      next
    end

    #IkpcofgsE
    #012345678
    # king philip came over for great spaghetti. Or is that King Phil Hugenholtz?
    to_upload = [
      primary_key,
      row[0],
      row[1].split(';')[0..6]
    ].flatten
    while to_upload.length < 9
      to_upload.push ''
    end
    tempfile.puts to_upload.join("\t")
    primary_key += 1
  end
  tempfile.close
  num_imported = primary_key-1
  log.info "Prepared #{num_imported} entries for import"

  log.info "Importing the temporary CSV file into the database"
  command = "sqlite3 #{options[:database_path]}"
  stdin = ".mode tabs\n.import #{tempfile.path} taxonomies\n"
  status, stdout, stderr = systemu command, 0=>stdin
  unless status.exitstatus == 0
    raise Exception, "Some kind of error running sqlite3 import. STDERR was #{stderr}"
  end
  log.info "Finished importing #{num_imported} taxonomy strings into the database"
end


