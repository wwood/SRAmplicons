require 'bio-krona'
require 'bio-sra'
require 'pp'

class SrampliconsController < ApplicationController
  caches_action :index

  def index
    @num_datasets = Cluster.select('distinct(sra_run_id)').count
    @num_pyrotags = Cluster.select('sum(num_sequences) as num_sequences').first.num_sequences
  end

  def run
    @run_id = params['run_id']

    runs = Sra.where(run_accession: @run_id).to_a
    raise unless runs.length == 1
    @run = runs[0]

    if !@run.study_entrez_link.nil?
      @pubmed_id = @run.study_entrez_link.split(': ')[1]
    end
  end


  def run_iframe
    run = params['run_id']

    # Extract a list of taxonomy arrays to num_sequences in that cluster
    # Some clusters will have the same taxonomy information, so need
    # to make each have unique taxonomy info artificially
    clusters = Cluster.includes(:taxonomy).where(:sra_run_id => run).load
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

  def prokmsa
    @taxonomy_ids = params['tax_ids'].split(/[\s,;]+/)
    @confident_only = confident_only?(params)

    # Find all those studies which include at least one of those representatives
    activerecord_fragment = Cluster.where(best_hit_id: @taxonomy_ids)
    activerecord_fragment = activerecord_fragment.confidently_assigned if @confident_only
    initial_clusters = activerecord_fragment.order('sum(num_sequences) desc').limit(100).group('sra_run_id')

    @grouped_clusters = order_initial_clusters(initial_clusters, activerecord_fragment)
    @example_taxonomy = @grouped_clusters[0].cluster.taxonomy
    @mode = :prokmsa
    render :action => :overview
  end

  def taxonomy
    @taxonomy = params['q'].strip
    @confident_only = confident_only?(params)

    if column = Taxonomy.guess_column_from_name(@taxonomy)
      @example_taxonomy = Taxonomy.where(column => @taxonomy).first
      if @example_taxonomy.nil?
        @example_taxonomy = Taxonomy.where(["#{column} like ?", "%#{@taxonomy}%"]).first
        if @example_taxonomy.nil?
          flash[:error] = "Unable to find taxonomy `#{taxonomy}'"
        else
          @taxonomy = @example_taxonomy.send(column)
        end
      end

      where_key = "taxonomies.#{column}"
      activerecord_fragment = Cluster.joins(:taxonomy).where(where_key => @taxonomy)

      activerecord_fragment = activerecord_fragment.confidently_assigned if @confident_only
      initial_clusters = activerecord_fragment.order('sum(num_sequences) desc').limit(100).group('sra_run_id')

      @grouped_clusters = order_initial_clusters(initial_clusters, activerecord_fragment)
    else
      raise "Can only work with greengenes IDs at the moment sorry."
    end
    @mode == :taxonomy
    render :action => :overview
  end

  def study
    @study_id = params['study_id']
    @prokmsa_ids = params['prokmsa_ids']
    @taxonomy_id = params['taxonomy_id']
    @confident_only = confident_only?(params)

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
    # These SQL statements could be consolidated now there's only 1 db, but eh
    @all_run_ids = Sra.where(study_accession: @study_id).collect do |s|
      @example_run ||= s
      s.run_accession
    end

    if @mode == :prokmsa
      query = Cluster.
        where(best_hit_id: @prokmsa_ids).
        where(sra_run_id: @all_run_ids).
        select('distinct(sra_run_id)')
      query = query.confidently_assigned if @confident_only

      @run_ids = query.collect do |cluster|
        cluster.sra_run_id
      end
    else
      column = Taxonomy.guess_column_from_name(@taxonomy_id)
      @taxonomy_where_column = "taxonomies.#{column}"
      query = Cluster.joins(:taxonomy).
        where(@taxonomy_where_column => @taxonomy_id).
        where(sra_run_id: @all_run_ids).
        select('distinct(sra_run_id)')
      query = query.confidently_assigned if @confident_only

      @run_ids = query.collect do |cluster|
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
        relative_abundance
      ])
    end
    @runs_and_relative_abundance.sort! do |a,b|
      -(a[1] <=> b[1])
    end
  end

  def study_generic
    @study_id = params['study_id']
    @example_run = Sra.where(study_accession: @study_id).first
    @runs = Sra.where(study_accession: @study_id)
  end

  def search_by_sra
    query = params['accession'].strip
    column = Bio::SRA::Accession.accession_to_column_name query
    eg = Sra.where(column => query).first
    redirect_to study_url(eg.study_accession)
  end

  def search_by_keyword
    #Would be faster if there was just a single database here so a proper
    # join could be done. Oh well.
    # Better yet would be a proper text searching framework. Should I leave this to NCBI?
    @keyword = params['keyword'].strip
    for_sql = "%#{@keyword}%"
    raise unless @keyword.length > 1


    sra_run_ids = Sra.where(
      'study_abstract like ? or study_description like ?',for_sql,for_sql).select(
      'run_accession').collect{|s| s.run_accession}
    cap = 1000
    @example_clusters = Cluster.where(:sra_run_id => sra_run_ids).select('distinct(sra_run_id)').limit(cap).to_a
    @possibly_more = (@example_clusters.length == cap)
    @example_clusters.uniq! do |c|
      c.sra.study_accession
    end
  end

  private
  # Given a list of clusters, order them such that the ones with
  # the highest abundance are first, and they are grouped by study.
  # Returned as an array of ProjectCluster objects
  def order_initial_clusters(initial_clusters, activerecord_fragment)1
    project_clusters = {}
    initial_clusters.includes(:sra).each do |c|
      # Work out the relative abundance. This could
      # probably be less computationally intensive, but oh well.
      # Effectively need to join across 2 distinct databases,
      # which isn't possible.
      num_with_them = activerecord_fragment.select('sum(num_sequences) as num_sequences').where(sra_run_id: c.sra_run_id).first.num_sequences
      num_total = Cluster.select('sum(num_sequences) as num_sequences').where(sra_run_id: c.sra_run_id).first.num_sequences
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

  # Parse confident_search in a consistent way
  def confident_only?(params)
    confidence = params['confident_only']
    return (confidence == 'on')
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
    if decimal < 0.001
      '<0.1'
    else
      "#{(decimal*100).round(1)}"
    end
  end
end


class Bio::SRA::Tables::SRA
  # Return the sample attributes as an array of triple values,
  # with a triple for each sample attribute
  def sample_attributes_array
    SRASampleAttributes.new(sample_attribute)
  end

  # Attempt to discern the longtitude and latitude from the metadata,
  # and return them as an array. Return nil if not possible.
  #
  # Data types to go:
  # ERR011357: 'geographic location (latitude and longitude) => 60.171350 N 25.005533 E'
  def longitude_latitude
    attrs = sample_attributes_array

    longitude = attrs.first_matching('longitude') #e.g. SRR027089
    longitude ||= attrs.first_matching('Geographic location (longitude)') #e.g. ERR193639

    latitude = attrs.first_matching('latitude')
    latitude ||= attrs.first_matching('Geographic location (latitude)')

    if longitude and latitude
      if longitude[1].match(/^\d+\.\d+$/) and latitude[1].match(/^\d+\.\d+$/)
        return longitude[1].to_f, latitude[1].to_f
      else
        # Hell begins here. e.g. ERR011387 => 40º 02’ N
        return nil
      end
    elsif hit = attrs.first_matching('lat_lon')
      if matches = hit[1].match(/^(\d+\.\d+) (\d+\.\d+)$/)
        return matches[1].to_f, matches[2].to_f
      else
        return nil
      end
    else
      return nil
    end
  end
end

# A class to manipulate the sample_attributes info in the SRA table
class SRASampleAttributes


  def initialize(sample_attributes)
    @attributes = []
    unless sample_attributes.nil? or sample_attributes.strip == ''
      @attributes = sample_attributes.split(' || ')
    end

    @attributes = @attributes.collect do |attribute|
      @attributes = attribute.split(': ')
    end
  end

  def threesomes
    @attributes.each do |splits|
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

  # Return the first entry that has attribute name == key,
  # compared case insensitively
  def first_matching(key)
    @attributes.find do |a|
      a[0].downcase == key.downcase
    end
  end
end
