FactoryGirl.define do
  factory :product do
    title 'My favorite product'

    trait :with_stock
    stocks { FactoryGirl.build_list(:stock, 1) }
  end
end
