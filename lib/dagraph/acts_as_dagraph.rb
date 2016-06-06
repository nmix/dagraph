module Dagraph
  module ActsAsDagraph
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods 
      def acts_as_dagraph(options = {}) 

        has_many :parent_edges,
          as: :dag_child,
          class_name:  "Dagraph::Edge",
          dependent: :destroy

        has_many :child_edges,
          as: :dag_parent,
          class_name:  "Dagraph::Edge",
          dependent: :destroy

        include Dagraph::ActsAsDagraph::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def add_child(node) 
        raise SelfCyclicError.exception("Must not add node to itself") if node == self
        Edge.create(dag_parent: self, dag_child: node)
      end

      def add_parent(node)
        raise SelfCyclicError.exception("Must not add node to itself") if node == self
        Edge.create(dag_parent: node, dag_child: self)
      end
    end

  end
end
ActiveRecord::Base.include(Dagraph::ActsAsDagraph)
