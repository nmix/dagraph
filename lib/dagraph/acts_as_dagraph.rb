module Dagraph
  module ActsAsDagraph
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods 
      def acts_as_dagraph(options = {}) 
        include Dagraph::Model
        include Dagraph::ActsAsDagraph::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def add_parent(node) 
        create_edge(node, self)
      end

      def add_child(node)
        create_edge(self, node)
      end

      def parents(args = {})
        parent_type = args[:parent_type] || self.class.name
        parent_edges.where(dag_parent_type: parent_type).map{ |e| e.dag_parent }
      end

      def children(args = {})
        child_type = args[:child_type] || self.class.name
        child_edges.where(dag_child_type: child_type).map{ |e| e.dag_child }
      end

      def routing
        routes.map{ |r| [r.id, r.route_nodes.nodes] }.to_h
      end

      def isolated?
        if parents.any? || children.any?
          false
        else
          true
        end
      end

      def ancestors(args = {})
        ancestor_type = args[:ancestor_type] || self.class.name
        anc = route_nodes.where('level > 0').map do |route_node| 
          route_node.route.route_nodes.where("node_type = ? AND level < ?", ancestor_type, route_node.level).nodes
        end
        anc.uniq.reject{ |i| i.empty? }
      end

      def descendants(args = {})
        descendant_type = args[:descendant_type] || self.class.name
        desc = route_nodes.map do |route_node|
          route_node.route.route_nodes.where("node_type = ? AND level > ?", descendant_type, route_node.level).nodes
        end
        desc.uniq.reject{ |i| i.empty? }
      end


    end

    def create_edge(parent, child)
      raise SelfCyclicError.exception("Must not add node to itself") if parent == child
      if parent.isolated? && child.isolated?
        # create a simple route 
        route = Route.create
        route.route_nodes.create(node: parent, level: 0)
        route.route_nodes.create(node: child, level: 1)
      elsif parent.children.count == 0 || child.routes.count < 2
        # expand existing routes
      else
        # create new route(s)
      end
      Edge.create(dag_parent: parent, dag_child: child)
    end

  end
end
ActiveRecord::Base.include(Dagraph::ActsAsDagraph)
