class Cluster < ActiveRecord::Base
  belongs_to :taxonomy, :foreign_key => :best_hit_id, :primary_key => :taxonomy_id
  belongs_to :sra, :foreign_key => :sra_run_id, :primary_key => :run_accession

  scope :confidently_assigned, -> {
    where('best_hit_length > ? and best_hit_percent_identity >= ?',99,97)
  }
end
