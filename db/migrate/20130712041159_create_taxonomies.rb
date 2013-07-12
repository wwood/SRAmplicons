class CreateTaxonomies < ActiveRecord::Migration
  def change
    create_table :taxonomies do |t|
      t.integer :taxonomy_id, :null => false

      t.string :kingdom
      t.string :phylum
      t.string :class_name
      t.string :order
      t.string :family
      t.string :genus
      t.string :species
    end
  end
end
