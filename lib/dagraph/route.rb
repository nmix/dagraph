
module Dagraph
  class Route < ActiveRecord::Base 
    self.table_name = "dagraph_routes"
    
    has_many :route_nodes, class_name:  "Dagraph::RouteNode", foreign_key: "route_id", dependent: :destroy

    alias nodes route_nodes

  end
end
