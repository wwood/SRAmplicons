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

  # e.g. k__Bacteria => :kingdom
  # or nil if unguessable
  def self.guess_column_from_name(taxon_name)
    if matches = taxon_name.match(/^([kpcofgs])__/)
      # We are dealing with a greengenes ID
      key = {
        'k' => :kingdom,
        'p' => :phylum,
        'c' => :class_name,
        'o' => :order,
        'f' => :family,
        'g' => :genus,
        's' => :species
      }
      return key[matches[1]]
    else
      return nil
    end
  end
end
