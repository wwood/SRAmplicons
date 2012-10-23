class AdddRunIdToClusterTaxonomies < ActiveRecord::Migration
  def up
    add_column :cluster_taxonomies, :run_identifier, :string
  end

  def down
    remove_column :cluster_taxonomies, :run_identifier
  end
end
