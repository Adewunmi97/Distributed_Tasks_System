require 'rails_helper'

RSpec.describe TaskPolicy, type: :policy do
  subject { described_class }

  let(:admin) { User.create!(email: "admin@example.com", password: "password123", role: "admin") }
  let(:manager) { User.create!(email: "manager@example.com", password: "password123", role: "manager") }
  let(:member) { User.create!(email: "member@example.com", password: "password123", role: "member") }
  let(:other_member) { User.create!(email: "other@example.com", password: "password123", role: "member") }
  
  let(:task) { Task.create!(title: "Test Task", creator: member, state: "draft") }

  permissions :index?, :show?, :create? do
    it "allows all authenticated users" do
      expect(subject).to permit(member, task)
      expect(subject).to permit(manager, task)
      expect(subject).to permit(admin, task)
    end
  end

  permissions :update? do
    it "allows the creator" do
      expect(subject).to permit(member, task)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_member, task)
    end
  end

  permissions :destroy? do
    it "allows the creator" do
      expect(subject).to permit(member, task)
    end

    it "allows admins" do
      expect(subject).to permit(admin, task)
    end

    it "denies other members" do
      expect(subject).not_to permit(other_member, task)
    end
  end

  permissions :assign? do
    it "allows managers" do
      expect(subject).to permit(manager, task)
    end

    it "allows admins" do
      expect(subject).to permit(admin, task)
    end

    it "denies regular members" do
      expect(subject).not_to permit(member, task)
    end
  end

  permissions :transition? do
    context "when task has assignee" do
      before { task.update!(assignee: member, state: "assigned") }

      it "allows the assignee" do
        expect(subject).to permit(member, task)
      end

      it "denies other users" do
        expect(subject).not_to permit(other_member, task)
      end
    end

    context "when task has no assignee" do
      it "allows the creator" do
        expect(subject).to permit(member, task)
      end

      it "denies other users" do
        expect(subject).not_to permit(other_member, task)
      end
    end
  end
end