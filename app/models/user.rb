require 'net/ldap'
class User < ActiveRecord::Base
  #login is set automatically by CAS; it should not be editable
  attr_accessible :first_name, :last_name, :nickname, :phone, :email, :affiliation, :is_banned
  
  def self.search_ldap(login)
    ldap = Net::LDAP.new(:host => "directory.yale.edu", :port => 389)
    filter = Net::LDAP::Filter.eq("uid", login)
    attrs = ["givenname", "sn", "uid", "mail", "collegename"]
    result = ldap.search(:base => "ou=People,o=yale.edu", :filter => filter, :attributes => attrs)
    return {:first_name  => result[0][:givenname],
            :last_name   => result[0][:sn],
            :nickname    => result[0][:eduPersonNickname],
            :phone       => result[0][:telephoneNumber],
            :login       => result[0][:uid],
            :email       => result[0][:mail],
            #:affiliation => (result[0][:organizationName].to_s + (" #{result[0][:college]}" unless result[0][:college].nil?).to_s + (" #{result[0][:collegename]}" unless result[0][:classYear].nil?).to_s)} unless result.empty?
            :affiliation => result[0][:organizationName]} unless result.empty?
  end
end
