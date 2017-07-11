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

ActiveRecord::Schema.define(version: 20170711140143) do

  create_table "dagraph_edges", force: :cascade do |t|
    t.string "dag_parent_type"
    t.integer "dag_parent_id"
    t.string "dag_child_type"
    t.integer "dag_child_id"
    t.integer "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dag_child_type", "dag_child_id"], name: "index_dagraph_edges_on_dag_child_type_and_dag_child_id"
    t.index ["dag_parent_type", "dag_parent_id"], name: "index_dagraph_edges_on_dag_parent_type_and_dag_parent_id"
  end

  create_table "dagraph_route_nodes", force: :cascade do |t|
    t.integer "route_id", null: false
    t.string "node_type"
    t.integer "node_id"
    t.integer "level"
    t.index ["node_type", "node_id"], name: "index_dagraph_route_nodes_on_node_type_and_node_id"
    t.index ["route_id"], name: "index_dagraph_route_nodes_on_route_id"
  end

  create_table "dagraph_routes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "units", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
