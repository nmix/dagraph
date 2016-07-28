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

      def parents(parent_type = self.class.name)
        parent_edges.where(dag_parent_type: parent_type).map{ |e| e.dag_parent }
      end

      def children(child_type = self.class.name)
        child_edges.where(dag_child_type: child_type).map{ |e| e.dag_child }
      end
    end

    def create_edge(parent, child)
      raise SelfCyclicError.exception("Must not add node to itself") if parent == child
      Edge.create(dag_parent: parent, dag_child: child)
      route = Route.create
      route.nodes.create(node: parent, level: 0)
      route.nodes.create(node: child, level: 1)
    end

  end
end
ActiveRecord::Base.include(Dagraph::ActsAsDagraph)
