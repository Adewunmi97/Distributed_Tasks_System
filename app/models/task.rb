class Task < ApplicationRecord
  # Enums
  enum :state, {
    draft: 'draft',
    assigned: 'assigned',
    in_progress: 'in_progress',
    completed: 'completed',
    cancelled: 'cancelled'
  }, prefix: true

  # Associations
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  belongs_to :assignee, class_name: 'User', foreign_key: 'assignee_id', optional: true
  has_many :events, class_name: 'Event', foreign_key: :task_id, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :state, presence: true, inclusion: { in: states.keys }
  validates :creator, presence: true
  validate :assignee_required_for_assigned_state

  # Scopes
  scope :by_state, ->(state) { where(state: state) }
  scope :assigned_to, ->(user) { where(assignee: user) }
  scope :created_by, ->(user) { where(creator: user) }
  scope :pending, -> { where(state: ['draft', 'assigned', 'in_progress']) }
  scope :completed_or_cancelled, -> { where(state: ['completed', 'cancelled']) }

  # Instance methods
  def assigned?
    assignee.present?
  end

  def can_be_assigned?
    state_draft? || state_assigned?
  end

  def can_transition_to?(new_state)
    valid_transitions[state.to_sym]&.include?(new_state.to_sym) || false
  end

  private

  def valid_transitions
    {
      draft: [:assigned, :cancelled],
      assigned: [:in_progress, :cancelled],
      in_progress: [:completed, :cancelled],
      completed: [],
      cancelled: []
    }
  end

  def assignee_required_for_assigned_state
    if state == 'assigned' && assignee_id.nil?
      errors.add(:assignee, 'must be present when task is assigned')
    end
  end
end