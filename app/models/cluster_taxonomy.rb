class ClusterTaxonomy < ActiveRecord::Base
  attr_accessible :taxonomy_id, :cluster
  
  belongs_to :taxonomy
end
