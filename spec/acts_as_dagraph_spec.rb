
RSpec.describe "ActsAsDagraph" do

  let(:unit) { create(:unit) }
  let(:unit_2) { create(:unit) }

  it "has a valid Unit factory" do
    expect(unit).to be_valid
  end

  context "when graph is empty" do
    describe "#add_child" do
      subject { unit.add_child(unit_2) }

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

    describe "#add_parent" do
      subject { unit.add_parent(unit_2) }
      
      it "creates an instance of Edge" do
        expect{ subject }.to change{ Dagraph::Edge.count }.by(1)
      end

      it "creates an instance of Route" do
        expect{ subject }.to change{ Dagraph::Route.count }.by(1)
      end

      it "creates 2 instances of RouteNodes" do
        expect{ subject }.to change{ Dagraph::RouteNode.count }.by(2)
      end
    end
  end

  context "when graph is arbitrary" do
    describe "#add_child" do
      it "raises exception if add self node" do
        expect {
          unit.add_child(unit)
        }.to raise_error(SelfCyclicError)
      end
    end
    describe "#add_parent" do
      it "raises exception if add self node" do
        expect {
          unit.add_parent(unit)
        }.to raise_error(SelfCyclicError)
      end
    end
  end

end
