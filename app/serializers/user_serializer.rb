class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :nickname, :phone,
    :affiliation, :terms_of_service_accepted, :role
end
