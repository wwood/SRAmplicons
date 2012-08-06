class CreateTaxonomies < ActiveRecord::Migration
  def change
    create_table :taxonomies do |t|
      t.string :taxonomy_string

      t.timestamps
    end
  end
end
