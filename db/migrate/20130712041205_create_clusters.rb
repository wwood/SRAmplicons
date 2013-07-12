class CreateClusters < ActiveRecord::Migration
  def change
    create_table :clusters do |t|
      t.string :sra_run_id, :null => false
      t.string :representative_id, :null => false
      t.integer :num_sequences
      t.integer :best_hit_id
      t.decimal :best_hit_percent_identity
      t.integer :best_hit_length
      t.string :best_hit_cigar
    end
  end
end
