
RSpec.describe "ActsAsDagraph" do

  let(:unit) { create(:unit) }
  let(:another_unit) { create(:unit) }
  let(:edge) { create(:edge) }

  before(:all) do
    create_graph
  end

  it "has a valid Unit factory" do
    expect(unit).to be_valid
  end

  it "has a valid Edge factory" do
    expect(edge).to be_valid
  end

  it "has a valid Route factory" do
    expect(create(:route)).to be_valid
  end

  it "has a valid RouteNode factory" do
    expect(create(:route_node)).to be_valid
  end

  shared_examples "a simple creating method" do
    describe "#create_edge" do
      it "creates an instance of Edge" do
        expect { subject }.to change{ Dagraph::Edge.count }.by(1)
      end

      it "does for isolated nodes" do
        expect{ subject }.to change{ Dagraph::Route.count }.by(1)
      end

      it "creates 2 instances of RouteNodes" do
        expect{ subject }.to change{ Dagraph::RouteNode.count }.by(2)
      end
    end
  end

  describe "#add_child" do
    subject { unit.add_child(another_unit) }
    it_behaves_like "a simple creating method"

    it "raises exception if add self node" do
      expect { unit.add_child(unit) }.to raise_error(SelfCyclicError)
    end

    it "raises exception if add ancestor node" do
      [
        [11, [7, 5]],
        [8, [7, 3]],
        [2, [7, 5, 11]],
        [9, [7, 5, 3, 11, 8]],
        [10, [7, 5, 3, 11]],
      ].each do |code, parent_codes|
        parent_codes.each do |parent_code|
          expect { node(code).add_child(node(parent_code)) }.to raise_error(CyclicError)
        end
      end
    end

    context "when graph is arbitrary" do
      before(:all) do
        create_graph(index: 100)
      end

      it "creates new routes for non-isolated nodes" do
        [
          [2, 105, 1],
          [2, 107, 4],
          [11, 111, 6],
          [9, 107, 12],
          [3, 108, 1]
        ].each do |parent_code, child_code, new_routes_count|
          expect {
            node(parent_code).add_child(node(child_code))
          }.to change{ Dagraph::Route.count }.by(new_routes_count)
        end
      end

      it "creates new routes for isolated child" do
        [7, 5, 3, 11, 8].each do |code|
          anc_count = node(code).ancestors.count
          anc_count = 1 if anc_count == 0
          expect{
            node(code).add_child(create(:unit)) 
            }.to change{ Dagraph::Route.count }.by(anc_count)
        end
      end

      it "does not create routes for isolated child" do
        [2, 9, 10].each do |code|
          expect {
            node(code).add_child(create(:unit))
          }.to_not change{ Dagraph::Route.count }
        end
      end
    end
  end

  describe "#add_parent" do
    subject { another_unit.add_parent(unit) }
    it_behaves_like "a simple creating method"

    it "raises exception if add self node" do
      expect { unit.add_parent(unit) }.to raise_error(SelfCyclicError)
    end

    it "raises exception if add descendant node" do
      [
        [7, [11,8,2,9,10]],
        [5, [11,2,9,10]],
        [11, [2,9,10]],
        [8, [9]],
      ].each do |code, child_codes|
        child_codes.each do |child_code|
          expect{ node(code).add_parent(node(child_code)) }.to raise_error(CyclicError)
        end
      end
    end

    context "when graph is arbitrary" do
      before(:all) do
        create_graph(index: 200)
      end

      it "creates new routes for non-isolated nodes" do
        [
          [2, 205, 1],
          [2, 207, 4],
          [11, 211, 6],
          [9, 207, 12],
          [3, 208, 1]
        ].each do |parent_code, child_code, new_routes_count|
          expect {
            node(child_code).add_parent(node(parent_code))
          }.to change{ Dagraph::Route.count }.by(new_routes_count)
        end
      end

      it "creates new routes for isolated parent" do
        [11, 8, 2, 9, 10].each do |code|
          desc_count = node(code).descendants.count
          desc_count = 1 if desc_count == 0
          expect{
            node(code).add_parent(create(:unit)) 
            }.to change{ Dagraph::Route.count }.by(desc_count)
        end
      end

      it "does not create routes for isolated parent" do
        [7, 5, 3].each do |code|
          expect {
            node(code).add_parent(create(:unit))
          }.to_not change{ Dagraph::Route.count }
        end
      end
    end
  end

  describe "#remove_child" do
    before(:each) do
      create_graph(index: 300)
      @edges = [
        [7,11, 3],  [5,11, 0], [7,8,1], [3,8,0],
        [11,2,1], [11,9,1], [8,9,1], [11,10,1], [3,10, 1]
      ]
    end

    it "destroy an Edge object" do
      @edges.each do |parent, child|
        expect {
          node(300+parent).remove_child(node(300+child))
        }.to change{ Dagraph::Edge.count }.by -1
      end
    end

    it "changes Route objects" do
      @edges.each do |parent, child, route_diff|
        expect {
          node(300 + parent).remove_child(node(300 + child))
        }.to change{ Dagraph::Route.count }.by -(route_diff)
      end
    end
  end

  describe "#remove_children" do
    before(:each) do
      create_graph(index: 300)
    end

    it "destroy Edge objects" do
      [[7,2],[5,1],[3,2],[11,3],[8,1],[2,0],[9,0],[10,0]].each do |code, edge_diff|
        expect {
          node(300 + code).remove_children
        }.to change{ Dagraph::Edge.count }.by -(edge_diff)
      end
    end

    it "changes Route objects" do
      [[7,4], [5,0],[3,1],[11,3],[8,1],[2,0],[9,0],[10,0]].each do |code, route_diff|
        expect {
          node(300 + code).remove_children
        }.to change{ Dagraph::Route.count }.by -(route_diff)
      end
    end
  end

  describe "#remove_parent" do
    before(:each) do
      create_graph(index: 300)
      @edges = [
        [2,11,2], [9,11,2], [9,8,0], [10,11,0], [10,3,1], 
        [11,7,1], [11,5,1], [8,7,1], [8,3,1]
      ]
    end

    it "destroy an Edge object" do
      @edges.each do |child, parent|
        expect {
          node(300+child).remove_parent(node(300+parent))
        }.to change{ Dagraph::Edge.count }.by -1
      end
    end

    it "changes Route objects" do
      @edges.each do |child, parent, route_diff|
        expect {
          node(300+child).remove_parent(node(300+parent))
        }.to change{ Dagraph::Route.count }.by -(route_diff)
      end
    end
  end

  describe "#remove_parents" do
    before(:each) do
      create_graph(index: 300)
    end

    it "destroy Edge objects" do
      [[2,1],[9,2],[10,2],[11,2],[8,2],[7,0],[5,0],[3,0]].each do |code, edge_diff|
        expect {
          node(300 + code).remove_parents
        }.to change{ Dagraph::Edge.count }.by -(edge_diff)
      end
    end

    it "changes Route objects" do
      [[11,3],[8,1],[9,2],[2,1]].each do |code, route_diff|
        expect {
          node(300 + code).remove_parents
        }.to change{ Dagraph::Route.count }.by -(route_diff)
      end
    end
  end

  describe "#isolated?" do
    it "creates isolated node" do
      expect(unit.isolated?).to be true
    end

    it "is not isolated in graph" do
      all_graph_nodes.each do |node|
        expect(node.isolated?).to be false
      end
    end
  end

  describe "#parents" do
    it "determines the amount of all parents for graph nodes" do
      [[7,0], [5,0], [3,0], [11,2], [8,2], [2,1], [9,2], [10,2]].each do |code, count|
        expect(node(code).parents.count).to eq count
      end
    end
  end

  describe "#children" do 
    it "determines the amount of all children for graph nodes" do
      [[7,2], [5,1], [3,2], [11,3], [8,1], [2,0], [9,0], [10,0]].each do |code, count|
        expect(node(code).children.count).to eq count
      end
    end
  end

  describe "#root?" do
    it "is root if have no parents" do
      [7, 5, 3].each do |code|
        expect(node(code).root?).to be true
      end
    end

    it "is not root if have any parent" do
      [11, 8, 2, 9, 10].each do |code|
        expect(node(code).root?).to be false
      end
    end
  end

  describe "#leaf?" do
    it "is leaf if have no children" do
      [2, 9, 10].each do |code|
        expect(node(code).leaf?).to be true
      end
    end

    it "is not leaf if have any child" do
      [7, 5, 3, 11, 8].each do |code|
        expect(node(code).leaf?).to be false
      end
    end
  end

  describe "#routes" do
    it "determines the amount of routes for graph nodes" do
      [[7,4], [5,3], [3,2], [11,6], [8,2], [2,2], [9,4], [10,3]].each do |code, count|
        expect(node(code).routes.count).to eq count
      end
    end
  end

  describe "#routing" do
    it "has empty routing for isolated node" do
      expect(unit.routing.count).to eq 0
    end

    it "determines the amount of routes for graph nodes" do
      [[7,4], [5,3], [3,2], [11,6], [8,2], [2,2], [9,4], [10,3]].each do |code, count|
        expect(node(code).routing.count).to eq count
      end
    end

    it "contains exactly nodes" do
      [
        [7, [[7,11,2], [7,11,9], [7,11,10], [7,8,9]]],
        [5, [[5,11,2], [5,11,9], [5,11,10]]],
        [3, [[3,8,9], [3,10]]],
        [11, [[7,11,2], [7,11,9], [7,11,10], [5,11,2], [5,11,9], [5,11,10]]],
        [8, [[7,8,9], [3,8,9]]],
        [2, [[7,11,2], [5,11,2]]],
        [9, [[7,11,9], [5,11,9], [7,8,9], [3,8,9]]],
        [10, [[7,11,10], [5,11,10], [3,10]]]
      ].each do |code, routes|
        expect(node(code).routing.values).to contain_exactly(*routes.map{|codes| nodes(*codes)})
      end
    end

    it "orders nodes by level" do
      all_graph_nodes.each do |node|
        node.routing.keys.each do |route_id|
          expect(Dagraph::Route.find(route_id).route_nodes).to eq(Dagraph::RouteNode.where(route_id: route_id).order(:level))
        end
      end
    end
  end

  describe "#ancestors" do
    it "has no ancestors for isolated node" do
      expect(unit.ancestors.count).to eq 0
    end

    it "determines the amount of ancestors" do
      [[7,0], [5,0], [3,0], [11,2], [8,2], [2,2], [9,4], [10,3]].each do |code, count|
        expect(node(code).ancestors.count).to eq count
      end
    end

    it "contains exactly nodes" do
      [
        [11, [[7], [5]]],
        [8, [[7], [3]]],
        [2, [[7,11], [5,11]]],
        [9, [[7,11], [5,11], [7,8], [3,8]]],
        [10, [[7,11], [5,11], [3]]]
      ].each do |code, routes|
        expect(node(code).ancestors).to contain_exactly(*routes.map{|codes| nodes(*codes)})
      end
    end
  end

  describe "#self_and_ancestors" do
    it "is self node on the end of each ancestor array" do
      [11, 8, 2, 9, 10].each do |code|
        node(code).self_and_ancestors.each do |ancestors_array|
          expect(ancestors_array).to end_with(node(code))
        end
      end
    end
  end

  describe "#descendants" do
    it "has no descendants for isolated node" do
      expect(unit.descendants.count).to eq 0
    end

    it "determines the amount of descendants" do
      [[7,4], [5,3], [3,2], [11,3], [8,1], [2,0], [9,0], [10,0]].each do |code, count|
        expect(node(code).descendants.count).to eq count
      end
    end

    it "contains exactly nodes" do
      [
        [7, [[11,2], [11,9], [11,10], [8,9]]],
        [5, [[11,2], [11,9], [11,10]]],
        [3, [[8,9], [10]]],
        [11, [[2], [9], [10]]],
        [8, [[9]]]
      ].each do |code, routes|
        expect(node(code).descendants).to contain_exactly(*routes.map{|codes| nodes(*codes)})
      end
    end
  end

  describe "#self_and_descendants" do
    it "is self node on the beginning of each descendant array" do
      [7, 5, 3, 11, 8].each do |code|
        node(code).self_and_descendants.each do |descendant_array|
          expect(descendant_array).to start_with(node(code))
        end
      end
    end
  end

  describe "#roots" do
    it "returns top nodes for graph routes" do
      [
        [2, [7,5]],
        [9, [7,5,3]],
        [10, [7,5,3]],
        [11, [7,5]],
        [8, [7,3]],
        [7, []], 
        [5, []],
        [3, []]
      ].each do |code, root_codes|
        expect(node(code).roots).to contain_exactly(*nodes(*root_codes))
      end
    end
  end

  describe "#leafs" do
    it "returns bottom nodes for graph routes" do
       [
        [7, [2,9,10]],
        [5, [2,9,10]],
        [3, [9,10]],
        [11, [2,9,10]],
        [8, [9]],
        [2, []],
        [9, []],
        [10, []]
       ].each do |code, leaf_codes|
        expect(node(code).leafs).to contain_exactly(*nodes(*leaf_codes))
       end
    end
  end

  describe ".roots" do
    it "contains top nodes" do
      expect(Unit.roots).to include(*nodes(7, 5, 3))
    end

    it "does not contain not top nodes" do 
      nodes(11, 8, 2, 9, 10).each do |node|
        expect(Unit.roots).not_to include(node)
      end
    end
  end

  describe ".leafs" do
    it "contains bottom nodes" do
      expect(Unit.leafs).to include(*nodes(2, 9, 10))
    end

    it "does not contain not bottom nodes" do
      nodes(7, 5, 3, 11, 8).each do |node|
        expect(Unit.leafs).not_to include(node)
      end
    end
  end
end
