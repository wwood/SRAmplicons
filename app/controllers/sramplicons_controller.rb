require 'bio-krona'
require 'pp'

class SrampliconsController < ApplicationController
  @@confident_assignment_clause = 'best_hit_length > 99 and best_hit_percent_identity >= 97'

  def run
    @run_id = params['run_id']

    runs = Bio::SRA::Tables::SRA.where(run_accession: @run_id).to_a
    raise unless runs.length == 1
    @run = runs[0]


    if !@run.study_entrez_link.nil?
      @pubmed_id = @run.study_entrez_link.split(': ')[1]
    end

    @google_scholar_query = '"'+[
      @run.run_accession,
      @run.sample_accession,
      @run.study_accession,
      @run.experiment_accession,
      @run.submission_accession,
    ].join('" or "')+'"'

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
      key.push "otu #{cluster.representative_id.gsub(/.+\./,'')}, #{cluster.best_hit_percent_identity.round}% over #{cluster.best_hit_length}bp, tax #{cluster.best_hit_id}"
      for_krona[key] = cluster.num_sequences
    end
    @krona_html = Bio::Krona.html for_krona, :resources_url => '/krona'

    render :partial => 'run_iframe'
  end

  def overview
    @taxonomy_ids = params['tax_ids'].split(/[\s,;]+/)

    # Find all those studies which include at least one of those representatives
    activerecord_fragment = Cluster.where(best_hit_id: @taxonomy_ids).where(@@confident_assignment_clause)
    initial_clusters = activerecord_fragment.order('sum(num_sequences) desc').limit(100).group('sra_run_id')

    @grouped_clusters = order_initial_clusters(initial_clusters, activerecord_fragment)
  end

  def taxonomy
    @taxonomy = params['q'].strip

    if column = Taxonomy.guess_column_from_name(@taxonomy)
      where_key = "taxonomies.#{column}"
      activerecord_fragment = Cluster.joins(:taxonomy).where(where_key => @taxonomy).where(@@confident_assignment_clause)
      initial_clusters = activerecord_fragment.order('sum(num_sequences) desc').limit(100).group('sra_run_id')

      @grouped_clusters = order_initial_clusters(initial_clusters, activerecord_fragment)
    else
      raise "Can only work with greengenes IDs at the moment sorry."
    end
  end

  def study
    @study_id = params['study_id']
    @prokmsa_ids = params['prokmsa_ids']
    @taxonomy_id = params['taxonomy_id']
    @mode = nil
    if @taxonomy_id
      @mode = :taxonomy
      @taxonomy_id = @taxonomy_id.strip
    elsif @prokmsa_ids
      @mode = :prokmsa
      @prokmsa_ids = @prokmsa_ids.split(/[\s,;]+/)
    else
      raise "Not yet implemented - need a taxonomy or prokMSA ID"
    end

    @example_run = nil
    @all_run_ids = Bio::SRA::Tables::SRA.where(study_accession: @study_id).collect do |s|
      @example_run ||= s
      s.run_accession
    end

    if @mode == :prokmsa
      @run_ids = Cluster.where(best_hit_id: @prokmsa_ids).where(sra_run_id: @all_run_ids).select('distinct(sra_run_id)').collect do |cluster|
        cluster.sra_run_id
      end
    else
      column = Taxonomy.guess_column_from_name(@taxonomy_id)
      @taxonomy_where_column = "taxonomies.#{column}"
      @run_ids = Cluster.joins(:taxonomy).where(
        @taxonomy_where_clause).where(
        sra_run_id: @all_run_ids).select('distinct(sra_run_id)').collect do |cluster|
        cluster.sra_run_id
      end
    end

    @runs_and_relative_abundance = []
    @run_ids.each do |run_id|
      fragment = Cluster.where(sra_run_id: run_id)
      positive_fragment = nil
      if @mode == :taxonomy
        positive_fragment = fragment.joins(:taxonomy).where(@taxonomy_where_column => @taxonomy_id)
      else
        positive_fragment = fragment.where(best_hit_id: @prokmsa_ids)
      end
      num_with_them = positive_fragment.reduce(0){|old, c| old += c.num_sequences}
      num_total = fragment.reduce(0){|old, c| old+=c.num_sequences}
      relative_abundance = num_with_them.to_f/num_total

      @runs_and_relative_abundance.push([
        run_id,
        HumanMaxPercent.human_max(relative_abundance)
      ])
    end
    @runs_and_relative_abundance.sort! do |a,b|
      (a[1] <=> b[1])
    end
  end

  private
  # Given a list of clusters, order them such that the ones with
  # the highest abundance are first, and they are grouped by study.
  # Returned as an array of ProjectCluster objects
  def order_initial_clusters(initial_clusters, activerecord_fragment)
    project_clusters = {}
    initial_clusters.each do |c|
      # Work out the relative abundance. This could
      # probably be less computationally intensive, but oh well.
      # Effectively need to join across 2 distinct databases,
      # which isn't possible.
      num_with_them = activerecord_fragment.where(sra_run_id: c.sra_run_id).reduce(0){|old, c| old += c.num_sequences}
      num_total = Cluster.where(sra_run_id: c.sra_run_id).reduce(0){|old, c| old+=c.num_sequences}
      relative_abundance = num_with_them.to_f/num_total

      proj = c.sra.study_accession
      if project_clusters[proj]
        project_clusters[proj].runs_containing += 1
        if relative_abundance > project_clusters[proj].max_percentage
          project_clusters[proj].max_percentage = relative_abundance
          project_clusters[proj].cluster = c
        end
      else
        project_clusters[proj] = ProjectCluster.new
        project_clusters[proj].max_percentage = relative_abundance
        project_clusters[proj].cluster = c
        project_clusters[proj].runs_containing = 1
      end
    end
    return project_clusters.values.sort do |a,b|
      -(a.max_percentage <=> b.max_percentage)
    end
  end

  def order_initial_clusters_runwise(initial_clusters, activerecord_fragment)
  end
end


class ProjectCluster
  attr_accessor :max_percentage
  attr_accessor :runs_containing
  attr_accessor :cluster

  def human_max_percent
    HumanMaxPercent.human_max @max_percentage
  end
end

class HumanMaxPercent
  def self.human_max(decimal)
    if decimal < 0.01
      '<1'
    else
      "#{(decimal*100).round}"
    end
  end
end


class Bio::SRA::Tables::SRA
  # Return the sample attributes as an array of triple values,
  # with a triple for each sample attribute
  def sample_attributes_array
    return [] if sample_attribute.nil? or sample_attribute.strip == ''

    return sample_attribute.split(' || ').collect do |attribute_pair|
      splits = attribute_pair.split(': ')
      if splits.length == 3
        splits
      elsif splits.length < 3 #hack
        splits.push '' while splits.length < 3
        splits
      else
        [
          splits[0],
          splits[1...(splits.length-1)],
          splits[splits.length-1]
        ]
      end
    end
  end
end
