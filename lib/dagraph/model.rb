module Dagraph
  module Model
    extend ActiveSupport::Concern

    included do 
      has_many :child_edges, as: :dag_parent, class_name:  "Dagraph::Edge", dependent: :destroy
      has_many :parent_edges, as: :dag_child, class_name:  "Dagraph::Edge", dependent: :destroy
      has_many :route_nodes, as: :node, class_name: "Dagraph::RouteNode", dependent: :destroy
    end
  end
end
