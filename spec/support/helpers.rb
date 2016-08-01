
module ActsAsDagraphHelpers

  def create_graph
    [7, 5, 3, 11, 8, 2, 9, 10].map{ |label| create(:unit, name: "graph", code: label)}
    [[7, 11], [7, 8], [11, 9], [8, 9], [11, 10], [5, 11], [11, 2], [3, 8], [3, 10]].each do |parent, child|
      create(:edge, dag_parent: node(parent), dag_child: node(child))
    end
    routes = create_list(:route, 10)
    nodes =  { 
      1 => [7, 11, 9], 
      2 => [7, 8, 9], 
      3 => [7, 11, 10], 
      4 => [5, 11, 9], 
      5 => [5, 11, 10],
      6 => [7, 11, 2],
      7 => [5, 11, 2],
      8 => [3, 8, 9],
      9 => [3, 10] }
    nodes.each do |route_index, route_nodes| 
      route_nodes.each_with_index do |unit_label, level|
        routes[route_index].route_nodes.create(node: node(unit_label), level: level)
      end
    end
  end

  def node(label)
    Unit.find_by(code: label)
  end

  def nodes(*codes)
    Unit.where(code: codes.to_a).to_a
  end

  def all_graph_nodes
    Unit.select(:id, :name, :code).where(name: "graph")
  end

end

RSpec.configure do |config|
  config.include ActsAsDagraphHelpers
end
