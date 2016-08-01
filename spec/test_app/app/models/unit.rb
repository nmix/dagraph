class Unit < ActiveRecord::Base
  acts_as_dagraph

  default_scope { select(:id, :code) }

end
