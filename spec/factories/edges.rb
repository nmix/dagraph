
require 'faker'

FactoryGirl.define do
  factory :edge, :class => 'Dagraph::Edge' do
    association :dag_parent, factory: :unit
    association :dag_child, factory: :unit
  end
end
