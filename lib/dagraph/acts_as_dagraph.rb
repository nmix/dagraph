 module Dagraph
  module ActsAsDagraph
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods 
      def acts_as_dagraph(options = {}) 
        include Dagraph::Model

        def roots(args = {})
          parent_edges = Edge.find_by_sql("
            SELECT DISTINCT id 
            FROM dagraph_edges 
            WHERE dag_parent_id NOT IN (SELECT dag_child_id FROM dagraph_edges)")
          Edge.where(id: parent_edges).parents.uniq
        end

        def leafs(args = {})
          child_edges = Edge.find_by_sql("
            SELECT DISTINCT id
            FROM dagraph_edges
            WHERE dag_child_id NOT IN (SELECT dag_parent_id FROM dagraph_edges)")
          Edge.where(id: child_edges).children.uniq
        end

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

      def remove_parent(node)
        remove_edge(node, self)
      end

      def remove_parents(args = {})
        parents(args).each { |parent| remove_edge(parent, self) }
      end

      def remove_child(node)
        remove_edge(self, node)
      end

      def remove_children(args = {})
        children(args).each { |child| remove_edge(self, child) }
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

      def root?(args = {})
        if parents(args).any?
          false
        else
          true
        end
      end

      def leaf?(args = {})
        if children(args).any?
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

      def self_and_ancestors(args = {})
        ancestors(args).map{ |item| item + [self] }
      end

      def descendants(args = {})
        descendant_type = args[:descendant_type] || self.class.name
        desc = route_nodes.map do |route_node|
          route_node.route.route_nodes.where("node_type = ? AND level > ?", descendant_type, route_node.level).nodes
        end
        desc.uniq.reject{ |i| i.empty? }
      end

      def self_and_descendants(args = {})
        descendants(args).map{ |item| [self] + item }
      end

      def roots(args = {})
        ancestors(args).map{ |anc_route| anc_route.first }.uniq
      end

      def leafs(args = {})
        descendants(args).map { |desc_route| desc_route.last }.uniq
      end

    end

    def create_edge(parent, child)
      raise SelfCyclicError if parent == child
      raise DuplicationError if Edge.find_by(dag_parent: parent, dag_child: child)
      raise CyclicError if parent.ancestors.flatten.uniq.include? child

      if parent.isolated? && child.isolated?
        # create a simple route 
        route = Route.create
        route.route_nodes.create(node: parent, level: 0)
        route.route_nodes.create(node: child, level: 1)
      else
        # --- prepare ancestors for new route(s)
        ancs = parent.self_and_ancestors
        ancs = [[parent]] unless ancs.any?
        if !parent.isolated? && parent.leaf?
          Route.destroy(parent.routes.ids)
        end
        # --- prepare descendants for new route(s)
        descs = child.self_and_descendants
        descs = [[child]] unless descs.any?
        if !child.isolated? && child.root?
          Route.destroy(child.routes.ids)
        end
        # --- create new route(s)
        ancs.each do |ancestor_array|
          descs.each do |descendant_array|
            route = Route.create
            (ancestor_array + descendant_array).each_with_index do |node, index|
              route.route_nodes.create(node: node, level: index)
            end
          end
        end
      end
      Edge.create(dag_parent: parent, dag_child: child)
    end

    def remove_edge(parent, child)
      edge = Edge.find_by(dag_parent: parent, dag_child: child)
      return edge unless edge
      # --- destroy edge
      edge.destroy
      # --- 
      common_routes = parent.routes.ids & child.routes.ids
      common_routes.each do |route_id|
        nodes = RouteNode.where(route_id: route_id).nodes
        separator = nodes.index(parent)
        hi_array = nodes[0..separator]
        low_array = nodes[separator+1..-1]
        # --- remove old route
        Route.destroy(route_id)
        # --- create new routes
        if hi_array.size > 1 && parent.leaf?
          route = Route.create
          hi_array.each_with_index do |node, index| 
            route.route_nodes.create(node: node, level: index)
          end
        end
        if low_array.size > 1 && child.root?
          route = Route.create
          low_array.each_with_index do |node, index|
            route.route_nodes.create(node: node, level: index)
          end
        end
      end
    end

  end
end
ActiveRecord::Base.include(Dagraph::ActsAsDagraph)
