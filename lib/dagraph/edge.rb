
module Dagraph
  class Edge < ActiveRecord::Base 

    self.table_name = "dagraph_edges"

    belongs_to :dag_parent, polymorphic: true
    belongs_to :dag_child, polymorphic: true
    belongs_to :weight, polymorphic: true
  end
end
