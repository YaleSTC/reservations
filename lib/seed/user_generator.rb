# frozen_string_literal: true
module UserGenerator
  def self.generate
    User.create do |u|
      u.first_name = FFaker::Name.first_name
      u.last_name = FFaker::Name.last_name
      u.nickname = FFaker::Name.first_name
      u.phone = FFaker::PhoneNumber.short_phone_number
      u.email = FFaker::Internet.email
      u.cas_login = FFaker::Internet.user_name if ENV['CAS_AUTH']
      u.affiliation = 'YC ' + %w(BK BR CC DC ES JE MC PC SM SY TC TD).sample +
                      ' ' + rand(2012..2015).to_s
      u.role = %w(normal checkout).sample
      u.username = ENV['CAS_AUTH'] ? u.cas_login : u.email
    end
  end

  def self.generate_superuser
    User.create! do |u|
      u.first_name = 'Donny'
      u.last_name = 'Darko'
      u.phone = '6666666666'
      u.email = 'email@email.com'
      u.affiliation = 'Your Mother'
      u.role = 'superuser'
      u.view_mode = 'superuser'
      u.username = 'dummy'
    end
  end
end
