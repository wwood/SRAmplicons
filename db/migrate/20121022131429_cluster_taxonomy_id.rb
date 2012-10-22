class ClusterTaxonomyId < ActiveRecord::Migration
  def up
    create_table :cluster_taxonomies do |t|
      t.string :cluster
      t.references :taxonomy
    end
  end

  def down
    drop_table :cluster_taxonomies
  end
end
