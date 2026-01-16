FactoryBot.define do
  factory :event, class: 'Event' do
    association :task, factory: :task
    event_type { 'task.created' }
    payload { { task_id: task.id, user_id: task.creator.id } }
    processed_at { nil }

    trait :task_created do
      event_type { 'task.created' }
      payload { { task_id: task.id, user_id: task.creator.id } }
    end

    trait :task_assigned do
      event_type { 'task.assigned' }
      payload { { task_id: task.id, assignee_id: task.assignee&.id } }
    end

    trait :task_completed do
      event_type { 'task.completed' }
      payload { { task_id: task.id, completed_by: task.assignee&.id || task.creator.id } }
    end

    trait :processed do
      processed_at { Time.current }
    end

    trait :unprocessed do
      processed_at { nil }
    end
  end
end
