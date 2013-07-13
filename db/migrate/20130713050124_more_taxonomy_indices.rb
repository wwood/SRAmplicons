class MoreTaxonomyIndices < ActiveRecord::Migration
  def change
    add_index :taxonomies, :taxonomy_id
  end
end
