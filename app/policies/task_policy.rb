class TaskPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can list tasks
  end

  def show?
    true # All authenticated users can view tasks
  end

  def create?
    true # All authenticated users can create tasks
  end

  def update?
    # Only creator can update task details
    user.id == record.creator_id
  end

  def destroy?
    # Only creator or admin can delete
    user.id == record.creator_id || user.role_admin?
  end

  def assign?
    # Only managers and admins can assign tasks
    user.can_assign_tasks?
  end

  def transition?
    # Only assignee can transition task states (or creator if unassigned)
    if record.assignee_id.present?
      user.id == record.assignee_id
    else
      user.id == record.creator_id
    end
  end

  class Scope < Scope
    def resolve
      # Users see tasks they created or are assigned to
      # Admins see all tasks
      if user.role_admin?
        scope.all
      else
        scope.where("creator_id = ? OR assignee_id = ?", user.id, user.id)
      end
    end
  end
end
