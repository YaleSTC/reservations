require 'net/ldap'
class User < ActiveRecord::Base
  has_many :reservations, :foreign_key => 'reserver_id'
  nilify_blanks :only => [:deleted_at] 
  attr_accessible :login, :first_name, :last_name, :nickname, :phone, :email, :affiliation, :is_banned, :is_checkout_person, :is_admin, :adminmode, :checkoutpersonmode, :normalusermode, :bannedmode, :deleted_at
  
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
  
  def can_checkout?
    self.is_checkout_person? or self.is_admin_in_adminmode? or self.is_admin_in_checkoutpersonmode?
  end

  def is_admin_in_adminmode?
    is_admin? && adminmode?
  end

  def is_admin_in_checkoutpersonmode?
    is_admin? && checkoutpersonmode?
  end

  def is_admin_in_bannedmode?
    is_admin? && bannedmode?
  end
  
  def equipment_objects
    self.reservations.collect{|r| r.equipment_objects}.flatten
  end
  
  def self.search_ldap(login)
    ldap = Net::LDAP.new(:host => "directory.yale.edu", :port => 389)
    filter = Net::LDAP::Filter.eq("uid", login)
    attrs = ["givenname", "sn", "eduPersonNickname", "telephoneNumber", "uid", "mail", "collegename", "curriculumshortname", "college", "class"]
    result = ldap.search(:base => "ou=People,o=yale.edu", :filter => filter, :attributes => attrs)
    return {:first_name  => result[0][:givenname][0],
            :last_name   => result[0][:sn][0],
            :nickname    => result[0][:eduPersonNickname][0],
            #:phone       => result[0][:telephoneNumber][0], #the phone number in the Yale phonebook is always wrong, let's not include it
            :login       => result[0][:uid][0],
            :email       => result[0][:mail][0],
            :affiliation => [result[0][:curriculumshortname], result[0][:college], result[0][:class]].select{|s| s.length > 0}.join(" ")} unless result.empty?
  end

  def self.select_options
    self.find(:all, :order => 'last_name ASC').collect{|item| ["#{item.last_name}, #{item.first_name}", item.id]}
  end
end
