class Taxonomy < ActiveRecord::Base
  has_many :clusters, :foreign_key => :best_hit_id
end
