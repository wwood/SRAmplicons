class Taxonomy < ActiveRecord::Base
  #has_many :clusters, :foreign_key => :best_hit_id, :primary_key => :taxonomy_id

  def taxonomy_as_array
    [
      kingdom,
      phylum,
      class_name,
      order,
      family,
      genus,
      species
    ]
  end
end
