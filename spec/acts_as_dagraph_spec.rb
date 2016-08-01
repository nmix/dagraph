
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

  shared_examples "a creating method" do
    describe "#create_edge" do
      it "creates an instance of Edge" do
        expect { subject }.to change{ Dagraph::Edge.count }.by(1)
      end

      context "creates routes" do
        it "does for isolated nodes" do
          expect{ subject }.to change{ Dagraph::Route.count }.by(1)
        end

        it "does not if parent has parent(s) and does not have children" do
          create(:edge, dag_child: unit)
          expect{ subject }.to_not change{ Dagraph::Route.count }
        end

        it "does not create if child has less than 2 routes and isolated parent" do
          create(:edge, dag_parent: another_unit)
          expect{ subject }.to_not change{ Dagraph::Route.count }
        end

        it "does not create if parent has parent(s) and child has less than 2 routes" do
          create(:edge, dag_child: unit)
          create(:edge, dag_parent: another_unit)
          expect{ subject }.to_not change{ Dagraph::Route.count }
        end
      end

      it "creates 2 instances of RouteNodes" do
        expect{ subject }.to change{ Dagraph::RouteNode.count }.by(2)
      end
    end
  end

  describe "#add_child" do
    subject { unit.add_child(another_unit) }
    it_behaves_like "a creating method"

    context "when graph is arbitrary" do
      it "raises exception if add self node" do
        expect { unit.add_child(unit) }.to raise_error(SelfCyclicError)
      end
    end
  end

  describe "#add_parent" do
    subject { another_unit.add_parent(unit) }
    it_behaves_like "a creating method"

    context "when graph is arbitrary" do
      it "raises exception if add self node" do
        expect { unit.add_parent(unit) }.to raise_error(SelfCyclicError)
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
    it "has not ancestors for isolated node" do
    end
  end

end
