
module Dagraph
  class Edge < ActiveRecord::Base 

    self.table_name = "dagraph_edges"

    belongs_to :dag_parent, polymorphic: true
    belongs_to :dag_child, polymorphic: true

    def self.parents
      all.map{ |e| e.dag_parent }
    end

    def self.children
      all.map{ |e| e.dag_child }
    end

    def self.weight(parent, child)
      edge = find_by(dag_parent: parent, dag_child: child)
      if edge
        edge.weight
      else
        0
      end
    end

    def self.weights(nodes)
      return [] if nodes.size < 2
      pairs = ([nodes[0]] + nodes[1..-2].map{ |n| [n, n] }.flatten + [nodes[-1]]).each_slice(2).to_a
      pairs.map{ |pair| Edge.find_by(dag_parent: pair[0], dag_child: pair[1]) }
    end

  end
end
