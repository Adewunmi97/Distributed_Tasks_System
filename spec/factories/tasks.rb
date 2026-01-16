FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    state { 'draft' }
    association :creator, factory: :user

    trait :assigned do
      state { 'assigned' }
      association :assignee, factory: :user
    end

    trait :in_progress do
      state { 'in_progress' }
      association :assignee, factory: :user
    end

    trait :completed do
      state { 'completed' }
      association :assignee, factory: :user
    end

    trait :cancelled do
      state { 'cancelled' }
    end
  end
end
