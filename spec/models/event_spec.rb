require "rails_helper"

RSpec.describe Event, type: :model do
  let(:task) { create(:task) }
  subject(:event) { build(:event, task: task) }

  describe "associations" do
    it { is_expected.to belong_to(:task).class_name("Task").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:payload) }

    it "accepts valid event_type format" do
      event.event_type = "task.completed"
      expect(event).to be_valid
    end

    it "rejects invalid event_type format" do
      event.event_type = "TaskCompleted"
      expect(event).not_to be_valid
    end
  end

  describe "scopes & processing" do
    it "is unprocessed by default" do
      expect(event.processed?).to be false
    end

    it "marks event as processed" do
      event.mark_as_processed!
      expect(event.processed?).to be true
    end
  end

  describe "event classification methods" do
    it "detects task events" do
      event.event_type = "task.created"
      expect(event.task_event?).to be true
      expect(event.user_event?).to be false
    end

    it "detects user events" do
      event.event_type = "user.created"
      expect(event.user_event?).to be true
      expect(event.task_event?).to be false
    end
  end
end
