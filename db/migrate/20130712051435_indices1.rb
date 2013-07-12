class Indices1 < ActiveRecord::Migration
  def change
    add_index :taxonomies, :taxonomy_id
    add_index :clusters, :sra_run_id
  end
end
