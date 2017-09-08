
module ActsAsDagraphHelpers

  def create_graph(args = {})
    index = args[:index] || 0
    [7, 5, 3, 11, 8, 2, 9, 10, 15, 20].map{ |label| create(:unit, name: "graph", code: index + label)}
    [
      [7, 11], [7, 8], [11, 9], [8, 9], [11, 10], 
      [5, 11], [11, 2], [3, 8], [3, 10]
    ].each do |parent, child|
      create(:edge, dag_parent: node(index + parent), 
        dag_child: node(index + child),
        weight: (parent - child).abs
        )
    end
    routes = create_list(:route, 9)
    nodes =  { 
      0 => [7, 11, 9], 
      1 => [7, 8, 9], 
      2 => [7, 11, 10], 
      3 => [5, 11, 9], 
      4 => [5, 11, 10],
      5 => [7, 11, 2],
      6 => [5, 11, 2],
      7 => [3, 8, 9],
      8 => [3, 10] }
    nodes.each do |route_index, route_nodes| 
      route_nodes.each_with_index do |unit_label, level|
        routes[route_index].route_nodes.create(node: node(index + unit_label), level: level)
      end
    end
  end

  def destroy_all_graphs
    Dagraph::Edge.destroy_all
    Dagraph::Route.destroy_all
    Unit.destroy_all
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
