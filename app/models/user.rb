class User < ActiveRecord::Base
  attr_accessible :login, :first_name, :last_name, :nickname, :phone, :email, :affiliation, :is_banned
end
