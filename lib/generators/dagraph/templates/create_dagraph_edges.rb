
class CreateDagraphEdges < ActiveRecord::Migration 

  def change 
    create_table :dagraph_edges do |t| 
      t.references :dag_parent, polymorphic: true, index: true
      t.references :dag_child, polymorphic: true, index: true
      t.references :weight, polymorphic: true, index: true

      t.timestamps null: false
    end 
  end 
end
