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
      def add_child(node) 
        raise SelfCyclicError.exception("Must not add node to itself") if node == self
        Edge.create(dag_parent: self, dag_child: node)
        route = Route.create
        route.nodes.create(node: self, level: 0)
        route.nodes.create(node: node, level: 1)
      end

      def add_parent(node)
        raise SelfCyclicError.exception("Must not add node to itself") if node == self
        Edge.create(dag_parent: node, dag_child: self)
        route = Route.create
        route.nodes.create(node: node, level: 0)
        route.nodes.create(node: self, level: 1)
      end
    end
  end
end
ActiveRecord::Base.include(Dagraph::ActsAsDagraph)
