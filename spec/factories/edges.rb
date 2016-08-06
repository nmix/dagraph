
require 'faker'

FactoryGirl.define do
  factory :edge, :class => 'Dagraph::Edge' do
    association :dag_parent, factory: :unit
    association :dag_child, factory: :unit
    weight { Faker::Number.between(1, 10) }

    factory :edge_with_route do
      after(:create) do |edge|
        route = create(:route)
        create(:route_node, route: route, node: edge.dag_parent)
        create(:route_node, route: route, node: edge.dag_child)
      end
    end
  end
end
