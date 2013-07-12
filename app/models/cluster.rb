class Cluster < ActiveRecord::Base
  belongs_to :taxonomy, :foreign_key => :best_hit_id, :primary_key => :taxonomy_id
end
