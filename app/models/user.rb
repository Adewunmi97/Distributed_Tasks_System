class User < ApplicationRecord
  has_secure_password

  enum :role, {
    member: "member",
    manager: "manager",
    admin: "admin"
  }, prefix: true

  has_many :created_tasks, class_name: 'Task', foreign_key: 'creator_id', dependent: :restrict_with_error
  has_many :assigned_tasks, class_name: 'Task', foreign_key: 'assignee_id', dependent: :nullify
  
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  validates :role, presence: true

  before_save :downcase_email

  def can_assign_tasks?
    role_manager? || role_admin?
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
