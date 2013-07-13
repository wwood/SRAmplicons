class Cluster < ActiveRecord::Base
  belongs_to :taxonomy, :foreign_key => :best_hit_id, :primary_key => :taxonomy_id
  belongs_to :sra, :foreign_key => :sra_run_id, :primary_key => :run_accession, :class_name => Bio::SRA::Tables::SRA
end
