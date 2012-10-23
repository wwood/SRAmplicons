class ClusterTaxonomy < ActiveRecord::Base
  attr_accessible :cluster, :taxonomy_id, :run_identifier
  
  belongs_to :taxonomy
end
