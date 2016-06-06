
RSpec.describe "ActsAsDagraph" do

  let(:unit) { create(:unit) }
  let(:unit_2) { create(:unit) }
  let(:unit_3) { create(:unit) }

  it "has a valid Unit factory" do
    expect(unit).to be_valid
  end

  describe "#add_child" do
    it "creates an instance of Edge" do
      expect {
        unit.add_child(unit_2)
      }.to change{ Dagraph::Edge.count }.by(1)
    end

    it "raises exception if add self node" do
      expect {
        unit.add_child(unit)
      }.to raise_error(SelfCyclicError)
    end
  end

  describe "#add_parent" do
    it "creates an instance of Edge" do
      expect {
        unit.add_parent(unit_2)
      }.to change{ Dagraph::Edge.count }.by(1)
    end

    it "raises exception if add self node" do
      expect {
        unit.add_parent(unit)
      }.to raise_error(SelfCyclicError)
    end
  end

end
