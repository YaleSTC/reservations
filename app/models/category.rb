class Category < ActiveRecord::Base
  attr_accessible :name, :max_per_user, :max_checkout_length
end
