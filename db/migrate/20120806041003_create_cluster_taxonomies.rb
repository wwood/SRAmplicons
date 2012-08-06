class CreateClusterTaxonomies < ActiveRecord::Migration
  def change
    change_table :clusters do |t|
      t.references :taxonomy
    end 
  end
end
