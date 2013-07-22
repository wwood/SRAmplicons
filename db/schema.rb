# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130713045817) do

  create_table "clusters", force: true do |t|
    t.string  "sra_run_id",                null: false
    t.string  "representative_id",         null: false
    t.integer "num_sequences"
    t.integer "best_hit_id"
    t.decimal "best_hit_percent_identity"
    t.integer "best_hit_length"
    t.string  "best_hit_cigar"
    t.string  "representative_sequence"
  end

  add_index "clusters", ["best_hit_id"], name: "index_clusters_on_best_hit_id"
  add_index "clusters", ["num_sequences"], name: "index_clusters_on_num_sequences"
  add_index "clusters", ["sra_run_id"], name: "index_clusters_on_sra_run_id"

# Could not dump table "col_desc" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

# Could not dump table "experiment" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

  create_table "metaInfo", id: false, force: true do |t|
    t.string "name",  limit: 50
    t.string "value", limit: 50
  end

# Could not dump table "run" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

# Could not dump table "sample" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

# Could not dump table "sra" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

# Could not dump table "sra_ft" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

# Could not dump table "sra_ft_content" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

  create_table "sra_ft_segdir", primary_key: "level", force: true do |t|
    t.integer "idx"
    t.integer "start_block"
    t.integer "leaves_end_block"
    t.integer "end_block"
    t.binary  "root"
  end

  add_index "sra_ft_segdir", ["level", "idx"], name: "sqlite_autoindex_sra_ft_segdir_1", unique: true

  create_table "sra_ft_segments", primary_key: "blockid", force: true do |t|
    t.binary "block"
  end

# Could not dump table "study" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

# Could not dump table "submission" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

  create_table "taxonomies", force: true do |t|
    t.integer "taxonomy_id", null: false
    t.string  "kingdom"
    t.string  "phylum"
    t.string  "class_name"
    t.string  "order"
    t.string  "family"
    t.string  "genus"
    t.string  "species"
  end

  add_index "taxonomies", ["class_name"], name: "index_taxonomies_on_class_name"
  add_index "taxonomies", ["family"], name: "index_taxonomies_on_family"
  add_index "taxonomies", ["genus"], name: "index_taxonomies_on_genus"
  add_index "taxonomies", ["kingdom"], name: "index_taxonomies_on_kingdom"
  add_index "taxonomies", ["order"], name: "index_taxonomies_on_order"
  add_index "taxonomies", ["phylum"], name: "index_taxonomies_on_phylum"
  add_index "taxonomies", ["species"], name: "index_taxonomies_on_species"
  add_index "taxonomies", ["taxonomy_id"], name: "index_taxonomies_on_taxonomy_id"

end
