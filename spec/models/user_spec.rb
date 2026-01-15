require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }
  let(:creator) { create(:user) }
  let(:assignee) { create(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("test@example.com").for(:email) }
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
  end

  describe "associations" do
    it { is_expected.to have_many(:created_tasks).class_name("Task").with_foreign_key("creator_id").dependent(:restrict_with_error) }
    it { is_expected.to have_many(:assigned_tasks).class_name("Task").with_foreign_key("assignee_id").dependent(:nullify) }
  end

  describe "roles" do
    it "defines valid enum roles" do
      expect(User.roles.keys).to match_array(%w[member manager admin])
    end

    it "returns correct booleans for roles" do
      admin = build(:user, :admin)
      expect(admin.role_admin?).to be true
      expect(admin.role_manager?).to be false
      expect(admin.can_assign_tasks?).to be true

      manager = build(:user, :manager)
      expect(manager.role_admin?).to be false
      expect(manager.role_manager?).to be true
      expect(manager.can_assign_tasks?).to be true

      member = build(:user)
      expect(member.role_admin?).to be false
      expect(member.role_manager?).to be false
      expect(member.can_assign_tasks?).to be false
    end
  end

  describe "callbacks" do
    it "downcases email before save" do
      user.email = "TEST@EXAMPLE.COM"
      user.save!
      expect(user.email).to eq("test@example.com")
    end
  end
end
