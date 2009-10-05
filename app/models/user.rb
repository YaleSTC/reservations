require 'net/ldap'
class User < ActiveRecord::Base
  attr_accessible :login, :first_name, :last_name, :nickname, :phone, :email, :affiliation, :is_banned
  
  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :phone
  validates_presence_of :email
  validates_presence_of :affiliation
  
  def name
    if nickname.nil? or nickname == ""
      first_name + " " + last_name
    else
      nickname + " " + last_name
    end
  end
  
  def self.search_ldap(login)
    ldap = Net::LDAP.new(:host => "directory.yale.edu", :port => 389)
    filter = Net::LDAP::Filter.eq("uid", login)
    attrs = ["givenname", "sn", "eduPersonNickname", "telephoneNumber", "uid", "mail", "collegename", "curriculumshortname", "college", "class"]
    result = ldap.search(:base => "ou=People,o=yale.edu", :filter => filter, :attributes => attrs)
    return {:first_name  => result[0][:givenname],
            :last_name   => result[0][:sn],
            :nickname    => result[0][:eduPersonNickname],
            :phone       => result[0][:telephoneNumber],
            :login       => result[0][:uid],
            :email       => result[0][:mail],
            :affiliation => [result[0][:curriculumshortname], result[0][:college], result[0][:class]].select{|s| s.length > 0}.join(" ")} unless result.empty?
  end
  
  def self.select_options
    self.find(:all, :order => 'last_name ASC').collect{|item| ["#{item.last_name}, #{item.first_name}", item.id]}
  end
end
