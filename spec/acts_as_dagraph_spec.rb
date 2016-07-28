
RSpec.describe "ActsAsDagraph" do

  let(:unit) { create(:unit) }
  let(:another_unit) { create(:unit) }
  let(:edge) { create(:edge) }

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

  describe "#parents" do
    before(:each) do
      create_list(:edge, 2, dag_child: unit)
    end

    it "has 2 parents" do
      expect(unit.parents.count).to eq 2
    end
  end

  describe "#children" do 
    before(:each) do
      create_list(:edge, 2, dag_parent: unit)
    end

    it "has 2 children" do
      expect(unit.children.count).to eq 2
    end
  end


  describe "#routes" do
    let(:parent_unit) { create(:edge_with_route).dag_parent }
    let(:child_unit) { create(:edge_with_route).dag_child }

    it "has minimum one route for parent_unit on the edge" do
      expect(parent_unit.routes.count).to be > 0
    end

    it "has minimum one route for child_unit on the edge" do
      expect(child_unit.routes.count).to be > 0
    end
  end

  describe "#isolated?" do
    it "creates isolated" do
      expect(unit.isolated?).to be true
    end

    it "is not isolated on edge" do
      expect(create(:edge_with_route).dag_parent.isolated?).to be false
    end
  end

end
