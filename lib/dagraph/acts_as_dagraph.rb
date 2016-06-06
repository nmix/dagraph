module Dagraph
  module ActsAsDagraph 
    extend ActiveSupport::Concern 

    included do
    end

    module ClassMethods 
      def acts_as_dagraph(options = {}) 
        # тут будет мой код
      end 
    end 
  end 
end 
ActiveRecord::Base.include(Dagraph::ActsAsDagraph)
