require "rails_helper"

RSpec.describe Task, type: :model do
  subject(:task) { build(:task) }

  describe "associations" do
    it { is_expected.to belong_to(:creator).class_name("User") }
    it { is_expected.to belong_to(:assignee).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:creator) }
  end

  describe "states" do
    it "defines valid states" do
      expect(Task.states.keys).to match_array(%w[draft assigned in_progress completed cancelled])
    end
  end

  describe "state transitions" do
    let(:task) { create(:task) }

    it "allows draft -> assigned" do
      expect(task.can_transition_to?(:assigned)).to be true
    end

    it "prevents completed -> in_progress" do
      task.update!(state: "completed")
      expect(task.can_transition_to?(:in_progress)).to be false
    end
  end

  describe "assignee requirements" do
    let(:creator) { create(:user) }
    let(:assignee) { create(:user) }
    
    it "is invalid if assigned without assignee" do
      task.state = "assigned"
      task.assignee = nil
      expect(task).not_to be_valid
      expect(task.errors[:assignee]).to include("must be present when task is assigned")
    end

    it "is valid if assigned with assignee" do
      creator = create(:user)
      assignee = create(:user)
      task = build(:task, :assigned, creator: creator, assignee: assignee)
      expect(task).to be_valid
    end    
  end
end
