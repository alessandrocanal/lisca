FactoryGirl.define do
  factory :social_account do
    user
    provider "facebook"
    uid { Faker::Number.number(6) }
    email { Faker::Internet.email }
    token { Faker::Number.number(6) }
    #data
  end

end
