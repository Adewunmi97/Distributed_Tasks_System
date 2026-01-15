FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    name { Faker::Name.name }
    role { "member" }

    trait :admin do
      role { "admin" }
    end

    trait :manager do
      role { "manager" }
    end
  end
end
