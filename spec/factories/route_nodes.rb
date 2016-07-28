
require 'faker'

FactoryGirl.define do
  factory :route_node, :class => 'Dagraph::RouteNode' do
    association :node, factory: :unit
    association :route, factory: :route
  end
end
