
module Dagraph
  class Edge < ActiveRecord::Base 

    self.table_name = "dagraph_edges"

    belongs_to :dag_parent, polymorphic: true
    belongs_to :dag_child, polymorphic: true
    belongs_to :weight, polymorphic: true

    def self.parents
      all.map{ |e| e.dag_parent }
    end

    def self.children
      all.map{ |e| e.dag_child }
    end
  end
end
