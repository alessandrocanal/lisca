FactoryGirl.define do

  password = "0123456789"

  factory :user do
    email { Faker::Internet.email }
    password  { password }
    password_confirmation  { password }

    factory :user_with_social_uid do
      transient do
        social_accounts_count 1
      end

      after(:create) do |user, evaluator|
        create_list(:social_account, evaluator.social_accounts_count, user: user)
      end

    end

    trait :access_token do
      after(:create) do |u|
        u.create_access_token
      end
    end
  end
end
