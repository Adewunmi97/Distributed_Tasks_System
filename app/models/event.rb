class Event < ApplicationRecord

  belongs_to :task, class_name: 'Task', optional: true

  validates :event_type, presence: true, format: { with: /\A[a-z_]+\.[a-z_]+\z/ }
  validates :payload, presence: true

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def processed?
    processed_at.present?
  end

  def mark_as_processed!
    update!(processed_at: Time.current)
  end

  def namespace
    event_type.split('.').first
  end
end
