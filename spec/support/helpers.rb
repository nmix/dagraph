
module ActsAsDagraphHelpers
  def graph
    units = create_list(:unit, 12)
    [[7, 11], [7, 8], [11, 9], [8, 9], [11, 10], [5, 11]].each do |parent, child|
      create(:edge, dag_parent: units[parent], dag_child: units[child])
    end
    routes = create_list(:route, 6)
    nodes =  { 1 => [7, 11, 9], 2 => [7, 8, 9], 3 => [7, 11, 10], 4 => [5, 11, 9], 5 => [5, 11, 10] }
    nodes.each do |route_index, route_nodes| 
      route_nodes.each_with_index do |unit_index, level|
        routes[route_index].nodes.create(node: units[unit_index], level: level)
      end
    end
    units
  end
end

RSpec.configure do |config|
  config.include ActsAsDagraphHelpers
end
