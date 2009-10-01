class User < ActiveRecord::Base
  #login is set automatically by CAS; it should not be editable
  attr_accessible :first_name, :last_name, :nickname, :phone, :email, :affiliation, :is_banned
end
