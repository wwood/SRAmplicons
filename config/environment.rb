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
puts Bio::SRA::Connection.connect(sradb_path)
