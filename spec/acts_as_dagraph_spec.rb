
RSpec.describe "ActsAsDagraph" do


  context "when graph is empty" do
    let(:unit) { create(:unit) }
    let(:unit_2) { create(:unit) }

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
    before(:all) do
      @u = create_list(:unit, 12)
      @unit = @u[0]
      @u[7].add_child(@u[11])
      @u[5].add_child(@u[11])
    end

    describe "#parents" do
      it "finds parent nodes for node 11" do
        expect(@u[11].parents('Unit').count).to eq 2
      end
    end

    describe "#add_child" do
      it "raises exception if add self node" do
        expect {
          @unit.add_child(@unit)
        }.to raise_error(SelfCyclicError)
      end
    end
    
    describe "#add_parent" do
      it "raises exception if add self node" do
        expect {
          @unit.add_parent(@unit)
        }.to raise_error(SelfCyclicError)
      end
    end
  end

end
