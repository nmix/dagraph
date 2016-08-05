
class CreateDagraph < ActiveRecord::Migration 

  def change 
    create_table :dagraph_edges do |t| 
      t.references :dag_parent, polymorphic: true, index: true
      t.references :dag_child, polymorphic: true, index: true
      t.integer :weight

      t.timestamps null: false
    end

    create_table :dagraph_routes do |t|
      t.timestamps null: false
    end

    create_table :dagraph_route_nodes do |t|
      t.integer :route_id, index: true, null: false
      t.references :node, polymorphic: true, index: true
      t.integer :level
    end
  end 
end
