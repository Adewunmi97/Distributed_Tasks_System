class User < ApplicationRecord
  # Secure password (adds password, password_confirmation attributes)
  has_secure_password

  # Associations
  has_many :created_tasks, class_name: 'Task', foreign_key: 'creator_id', dependent: :destroy
  has_many :assigned_tasks, class_name: 'Task', foreign_key: 'assignee_id', dependent: :nullify

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: 'must be a valid email address' }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :role, presence: true, inclusion: { in: %w[admin manager member], message: '%{value} is not a valid role' }

  # Callbacks
  before_save :downcase_email

  # Enum-like methods (manual implementation)
  def self.roles
    %w[admin manager member]
  end

  def admin?
    role == 'admin'
  end

  def manager?
    role == 'manager'
  end

  def member?
    role == 'member'
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end