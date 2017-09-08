module Dagraph
  module ActsAsDagraph
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods 
      def acts_as_dagraph
        include Dagraph::Model

        def roots
          parent_edges = Edge.find_by_sql("
            SELECT DISTINCT id 
            FROM dagraph_edges 
            WHERE dag_parent_id NOT IN (SELECT dag_child_id FROM dagraph_edges)")
          Edge.where(id: parent_edges).parents.uniq
        end

        def leafs
          child_edges = Edge.find_by_sql("
            SELECT DISTINCT id
            FROM dagraph_edges
            WHERE dag_child_id NOT IN (SELECT dag_parent_id FROM dagraph_edges)")
          Edge.where(id: child_edges).children.uniq
        end

        def isolated
          graph_ids = Dagraph::Edge.all.map{|e| [e.dag_parent_id, e.dag_child_id] }.flatten.uniq
          Unit.where(id: ids - graph_ids).to_a
        end

        def not_leafs
          roots + isolated
        end

        include Dagraph::ActsAsDagraph::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def add_parent(node, weight = 0) 
        create_edge(node, self, weight)
      end

      def add_child(node, weight = 0)
        create_edge(self, node, weight)
      end

      def remove_parent(node)
        remove_edge(node, self)
        parents
      end

      def remove_parents(args = {})
        parents(args).each { |parent| remove_edge(parent, self) }
        parents
      end

      def remove_child(node)
        remove_edge(self, node)
        children
      end

      def remove_children(args = {})
        children(args).each { |child| remove_edge(self, child) }
        children
      end

      def parents(args = {})
        parent_type = args[:parent_type] || self.class.name
        parent_edges.where(dag_parent_type: parent_type).map{ |e| args[:with_weight] ? [e.dag_parent, e.weight] : e.dag_parent }
      end

      def parents_weights(args = {})
        args[:with_weight] = 1
        parents(args)
      end

      def children(args = {})
        child_type = args[:child_type] || self.class.name
        child_edges.where(dag_child_type: child_type).map{ |e| args[:with_weight] ? [e.dag_child, e.weight] : e.dag_child }
      end

      def children_weights(args = {})
        args[:with_weight] = 1
        children(args)
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

      def ancestors_edges(args = {})
        self_and_ancestors(args).map{ |nodes| Edge.weights(nodes) } 
        # => [[edge, edge, ...], [edge, edge, ...], ...]
      end

      def ancestors_weights(args = {})
        ancestors_edges(args).map{ |route| route.map{|edge| [edge.dag_parent, edge.weight] } } 
        # =>  [ [ [node, weight], [node, weight], ... ], [ ... ], ... ]
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

      def descendants_edges(args = {})
        self_and_descendants(args).map{ |nodes| Edge.weights(nodes) } 
        # => [[edge, edge, ...], [edge, edge, ...], ...]
      end

      def descendants_weights(args = {})
        descendants_edges(args).map{ |route| route.map{|edge| [edge.dag_child, edge.weight] } } 
        # =>  [ [ [node, weight], [node, weight], ... ], [ ... ], ... ]
      end

      def descendants_assembled(args = {})
        # --- descendants edges with calculated weights
        dec = descendants_edges(args).map {|route| route.inject([]){|acc, edge| acc << [edge, acc.last ? acc.last[1]*edge.weight : edge.weight] } } 
        # => [ [[edge, weight], [edge, weight], ...], [...]]
        # ---
        # --- descendant non-uniq units with calculated weight
        de_uniq = dec.flatten.each_slice(2).to_a.uniq.map{|e,w| [e.dag_child, w]}
        # => [ [unit, weight], [unit, weight], ...]]
        # ---
        # --- descendant uniq units with calculated (including non-uniq) weights
        de_uniq.inject({}){|acc, uw| acc.has_key?(uw[0]) ? acc[uw[0]] += uw[1] : acc[uw[0]] = uw[1] ; acc }.to_a
        # => [ [unit, weight], [unit, weight], ...]]
      end

      def roots(args = {})
        ancestors(args).map{ |anc_route| anc_route.first }.uniq
      end

      def leafs(args = {})
        descendants(args).map { |desc_route| desc_route.last }.uniq
      end

    end

    def create_edge(parent, child, weight)
      raise SelfCyclicError if parent == child
      raise DuplicationError if Edge.find_by(dag_parent: parent, dag_child: child)
      raise CyclicError if parent.ancestors.flatten.uniq.include? child
      # ---
      if parent.isolated? && child.isolated?
        # --- create a simple route 
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
      Edge.create(dag_parent: parent, dag_child: child, weight: weight)
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
