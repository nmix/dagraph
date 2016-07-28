
RSpec.describe "ActsAsDagraph" do

  let(:unit) { create(:unit) }
  let(:unit_2) { create(:unit) }
  let(:edge) { create(:edge) }

  it "has a valid Unit factory" do
    expect(unit).to be_valid
  end

  it "has a valid Edge factory" do
    expect(edge).to be_valid
  end

  shared_examples "a creating method" do
    describe "#create_edge" do
      it "creates an instance of Edge" do
        expect { subject }.to change{ Dagraph::Edge.count }.by(1)
      end

      it "creates an instance of Route" do
        expect{ subject }.to change{ Dagraph::Route.count }.by(1)
      end

      it "creates 2 instances of RouteNodes" do
        expect{ subject }.to change{ Dagraph::RouteNode.count }.by(2)
      end
    end
  end

  describe "#add_child" do
    subject { unit.add_child(unit_2) }
    it_behaves_like "a creating method"

    context "when graph is arbitrary" do
      it "raises exception if add self node" do
        expect { unit.add_child(unit) }.to raise_error(SelfCyclicError)
      end
    end
  end

  describe "#add_parent" do
    subject { unit.add_parent(unit_2 ) }
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

    it "has 2 parents" do
      expect(unit.children.count).to eq 2
    end
  end

end
