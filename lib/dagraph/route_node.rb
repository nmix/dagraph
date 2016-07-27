
module Dagraph
  class RouteNode < ActiveRecord::Base 

    self.table_name = "dagraph_route_nodes"

    belongs_to :node, polymorphic: true
    belongs_to :route, class_name:  "Dagraph::Route"

  end
end
