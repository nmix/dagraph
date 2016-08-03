module Dagraph
  module ActsAsDagraph
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods 
      def acts_as_dagraph(options = {}) 
        include Dagraph::Model

        def report
          "routes: #{Route.all.size},   route_nodes: #{RouteNode.all.size},   units: #{Unit.all.size}"
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

    end

    def create_edge(parent, child)
      raise SelfCyclicError if parent == child
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

  end
end
ActiveRecord::Base.include(Dagraph::ActsAsDagraph)
