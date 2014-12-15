class Sra < Bio::SRA::Tables::SRA
  has_many :clusters, :foreign_key => :sra_run_id, :primary_key => :run_accession
end
