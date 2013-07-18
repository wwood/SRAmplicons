require 'bio'
require 'bio-krona'


# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Sramplicons::Application.initialize!


# Connect to the SRAdb
require 'bio-sra'
sradb_path = File.join(File.dirname(__FILE__),'..','db','SRAmetadb.sqlite3')
$stderr.puts "Connecting to SRAdb #{sradb_path}"
connection = Bio::SRA::Connection.connect(sradb_path)
$stderr.puts "May or may not be connected, lets test.."
if Bio::SRA::Tables::SRA.first
  $stderr.puts "Appear to be connected to the SRAdb, good."
end
