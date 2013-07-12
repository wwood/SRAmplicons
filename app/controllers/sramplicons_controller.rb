require 'bio-krona'

class SrampliconsController < ApplicationController
  def run
    @run_id = params['run_id']

    runs = Bio::SRA::Tables::SRA.where(run_accession: @run_id).all
    raise unless runs.length == 1
    @run = runs[0]
  end


  def run_iframe
    run = params['run_id']
    puts "Working with run: #{run}"

    # Extract a list of taxonomy arrays to num_sequences in that cluster
    # Some clusters will have the same taxonomy information, so need
    # to make each have unique taxonomy info artificially
    clusters = Cluster.includes(:taxonomy).where(:sra_run_id => run).load
    puts "Found #{clusters.length} clusters in this run id"
    for_krona = {}
    clusters.each do |cluster|
      key = ['unassigned']
      if cluster.taxonomy
        key = cluster.taxonomy.taxonomy_as_array
      end
      key.push "otu #{cluster.representative_id.gsub(/.+\./,'')}, #{cluster.best_hit_percent_identity.round}% over #{cluster.best_hit_length}bp"
      for_krona[key] = cluster.num_sequences
    end
    @krona_html = Bio::Krona.html for_krona, :resources_url => '/krona'

    render :partial => 'run_iframe'
  end
end
