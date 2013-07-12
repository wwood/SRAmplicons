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

ActiveRecord::Schema.define(version: 20130712051435) do

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

  add_index "clusters", ["sra_run_id"], name: "index_clusters_on_sra_run_id"

  create_table "taxonomies", force: true do |t|
    t.integer "taxonomy_id", null: false
    t.string  "kingdom"
    t.string  "phylum"
    t.string  "class"
    t.string  "order"
    t.string  "family"
    t.string  "genus"
    t.string  "species"
  end

  add_index "taxonomies", ["taxonomy_id"], name: "index_taxonomies_on_taxonomy_id"

end
