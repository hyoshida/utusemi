FactoryGirl.define do
  factory :product do
    title 'My favorite product'

    trait :with_stock do
      stocks { build_list(:stock, 1) }
    end
  end
end
