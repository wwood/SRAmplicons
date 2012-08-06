# A rake task to import the merged GG/Silva taxonomy

desc "import taxonomy from the merged gg/silva database"
task :import_taxonomy => :environment do
  taxonomy_file = File.join(Rails.root,'data','merged_gg_silva_taxo.txt')
  
  require 'csv'
  require 'progressbar'
  
  progress = ProgressBar.new('taxonomy_import',`wc -l '#{taxonomy_file}'`.to_i)
  Taxonomy.transaction do
    CSV.foreach(taxonomy_file, :headers => true, :col_sep => "\t") do |row|
      Taxonomy.create!({
        :taxonomy_id => row[0],
        :taxonomy_string => row[1],
      })
      progress.inc
    end
  end
  progress.finish
end