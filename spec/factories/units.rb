
require 'faker'

FactoryGirl.define do
  factory :unit, :class => 'Unit' do
    code { Faker::Business.credit_card_number }
    name { Faker::Commerce.product_name }
  end
end
