#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'csv'
require 'tempfile'
require 'systemu'
require 'progressbar'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = 'sramplicons'

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
}
o = OptionParser.new do |opts|
  opts.banner = "
    Usage: #{SCRIPT_NAME} -t taxonomy_file -d database_file

    Upload the taxonomy in the taxonomy file to the SRAmplicons database \n"


  opts.on('-c','--clusters PATH', 'Path the to clusters file, which contains one cluster per line e.g. DRR001167.10	2	152842	96.1864406779661	236	14S236M	k__Bacteria;p__Bacteroidetes;c__[Saprospirae];o__[Saprospirales];f__Chitinophagaceae;g__;s__	TCAGCATAGTAGTGTCCTAC') do |arg|
    options[:clusters_path] = arg
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

if ARGV.length != 0 or options[:database_path].nil? or options[:clusters_path].nil?
  $stderr.puts o
  exit 1
end

# Setup logging
Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)

progress = ProgressBar.new('prep_upload', `wc -l #{options[:clusters_path]}`.to_i)
Tempfile.open('tax_data') do |tempfile|
  log.info "Creating CSV file for upload.."
  primary_key = 1
  CSV.foreach(options[:clusters_path],:col_sep => "\t") do |row|
    to_upload = []

    #t.string :sra_run_id, :null => false
    #t.string :representative_id, :null => false
    #t.integer :num_sequences
    #t.integer :best_hit_id
    #t.decimal :best_hit_percent_identity
    #t.integet :best_hit_length
    #t.string best_hit_cigar
    if row[2] == '-' #no assigned taxonomy to rep seq
      to_upload = [
        primary_key,
        row[0].gsub(/\..+/,''),
        row[0],
        row[1],
        ['']*5
      ].flatten
    else
      #Something with taxonomy assigned

      #0 DRR001167.10
      #1 2
      #2 152842
      #3 96.1864406779661
      #4 236
      #5 14S236M
      #6 k__Bacteria;p__Bacteroidetes;c__[Saprospirae];o__[Saprospirales];f__Chitinophagaceae;g__;s__
      #7 TCAGCATAGTAGTGTCCTACG
      to_upload = [
        primary_key,
        row[0].gsub(/\..+/,''),
        row[0],
        row[1],
        row[2],
        row[3],
        row[4],
        row[5],
        row[7],
      ]
    end
    tempfile.puts to_upload.join("\t")
    primary_key += 1
    progress.inc
  end
  tempfile.close
  progress.finish

  num_imported = primary_key-1
  log.info "Prepared #{num_imported} entries for import"

  log.info "Importing the temporary CSV file into the database"
  command = "sqlite3 #{options[:database_path]}"
  stdin = ".mode tabs\n.import #{tempfile.path} clusters\n"
  status, stdout, stderr = systemu command, 0=>stdin
  unless status.exitstatus == 0
    raise Exception, "Some kind of error running sqlite3 import. STDERR was #{stderr}"
  end
  log.info "Finished importing #{num_imported} entries into the database"
end


