class TaxonomyIndices < ActiveRecord::Migration
  def change
    add_index :taxonomies, :kingdom
    add_index :taxonomies, :phylum
    add_index :taxonomies, :class_name
    add_index :taxonomies, :order
    add_index :taxonomies, :family
    add_index :taxonomies, :genus
    add_index :taxonomies, :species
  end
end
