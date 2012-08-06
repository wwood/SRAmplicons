class AddTaxonomyId < ActiveRecord::Migration
  def up
    add_column :taxonomies, :taxonomy_id, :string, :unique => true
  end

  def down
    remove_column :taxonomies, :taxonomy_id
  end
end
