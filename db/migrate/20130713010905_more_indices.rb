class MoreIndices < ActiveRecord::Migration
  def change
    add_index :clusters, :best_hit_id
    add_index :clusters, :num_sequences
  end
end
