
module Dagraph
  class Route < ActiveRecord::Base 
    self.table_name = "dagraph_routes"
    has_many :route_nodes, -> { order(:level) }, class_name:  "Dagraph::RouteNode", foreign_key: "route_id", dependent: :destroy
  end
end
