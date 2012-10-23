# A rake task to import an SRA run with assigned taxonomy into this rails application
require 'csv'

desc "import an assigned taxonomy output of clustered sequences"
task :import_sra_run, [:glob] => :environment do |t, args|
  # Get a list of the assigned_taxonomy files that we are working with here
  glob = args[:glob]
  assigned_taxonomies = Dir.glob(glob)
  $stderr.puts "Found #{assigned_taxonomies.length} different files to upload into the database"
  
  assigned_taxonomies.each do |assigned_taxonomy_file|
    $stderr.puts "Uploading #{assigned_taxonomy_file}"
    
    cluster1 = nil
    taxonomy1 = nil
    run_identifier1 = nil
    values_to_insert = []
    count = 0
    
    # I'll never understand why auto-increment doesn't just work
    max_id_row = ClusterTaxonomy.order('id desc').first
    first_primary_key = nil
    if max_id_row.nil?
      first_primary_key = 1
    else
      first_primary_key = max_id_row.id+1
    end
    primary_key = first_primary_key
    
    execute_sql = lambda do
      ActiveRecord::Base.connection.execute "INSERT INTO cluster_taxonomies select #{first_primary_key} as 'id', '#{cluster1}' as 'cluster_name', #{taxonomy1} as taxonomy_id, '#{run_identifier1}' as 'run_identifier'  #{values_to_insert.join(" ")}"
    end
    
    CSV.foreach(assigned_taxonomy_file, :col_sep => "\t") do |row|
      cluster_id = row[0]
      taxonomy_id = row[3]
      run_identifier = cluster_id.split('.')[0]
      
      unless taxonomy_id == '-'
        if cluster1.nil?
          #$stderr.puts [cluster_id, taxonomy_id, run_identifier].join("\t")
          cluster1 = cluster_id
          taxonomy1 = taxonomy_id
          run_identifier1 = run_identifier
        else
          values_to_insert.push " union select #{primary_key}, '#{cluster_id}', #{taxonomy_id}, '#{run_identifier}'"
        end
        primary_key += 1
      end
      count += 1
      
      if count == 500 #sqlite doesn't handle bigger than this, by default
        $stderr.puts "Running sql command since max of 500 was reached"
        execute_sql.call
        
        values_to_insert = []
        cluster1 = nil
        taxonomy1 = nil
        count = 0
        first_primary_key = primary_key
      end
    end
    $stderr.puts "Running the final sql command for this CSV file"
    execute_sql.call
  end
end
