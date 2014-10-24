require 'net/ldap'

class User < ActiveRecord::Base
  # Include cas devise module
  if ENV['CAS_AUTH']
    devise :cas_authenticatable
  else
    devise :database_authenticatable # THIS IS BROKEN... we need to heavily
    # tweak the User resource to get it working w/ Devise and flexible enough
    # to support other authentication methods
  end
  has_many :reservations, foreign_key: 'reserver_id', dependent: :destroy
  has_and_belongs_to_many :requirements,
                          class_name: "Requirement",
                          association_foreign_key: "requirement_id",
                          join_table: "users_requirements"

  attr_accessor   :full_query, :created_by_admin, :user_type, :csv_import

  validates :username,    presence: true,
                          uniqueness: true
  validates :first_name,
            :last_name,
            :affiliation, presence: true
  validates :phone,       presence:    true,
                          format:      { with: /\A\S[0-9\+\/\(\)\s\-]*\z/i },
                          length:      { minimum: 10 }, unless: lambda {|x| x.skip_phone_validation?}

  validates :email,       presence:    true,
                          uniqueness: true,
                          format:      { with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i }
  validates :nickname,    format:      { with: /\A[^0-9`!@#\$%\^&*+_=]+\z/ },
                          allow_blank: true
  validates :terms_of_service_accepted,
                          acceptance: {accept: true, message: "You must accept the terms of service."},
                          on: :create,
                          if: Proc.new { |u| !u.created_by_admin == "true" }
  validates :role,
            :view_mode,   inclusion: { in: ['admin', 'normal', 'checkout', 'superuser', 'banned', 'guest'] }
  validate :view_mode_reset

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, lambda { where("role != 'banned'") }
  scope :no_phone, lambda { where("phone = ? OR phone IS NULL", '') }

  # ------- validations -------- #
  def skip_phone_validation?
    return true unless AppConfig.first
    return true unless AppConfig.first.require_phone
    return true if missing_phone
    return !@csv_import.nil?
  end

  def view_mode_reset
    return if role == 'superuser'
    return if role == 'admin' && view_mode != 'superuser'
    self.view_mode = role
  end
  # ------- end validations -------- #

  def name
    "#{(nickname.blank? ? first_name : nickname)} #{last_name}"
  end

  def equipment_objects
    self.reservations.collect{ |r| r.equipment_object }.flatten
  end


  def self.search_ldap(login)
    return nil if login.blank?

    ldap = Net::LDAP.new(host: "directory.yale.edu", port: 389)
    filter = Net::LDAP::Filter.eq("uid", login)
    attrs = ["givenname", "sn", "eduPersonNickname", "telephoneNumber", "uid",
             "mail", "collegename", "curriculumshortname", "college", "class"]
    result = ldap.search(base: "ou=People,o=yale.edu", filter: filter, attributes: attrs)
    unless result.empty?
      return { first_name:  result[0][:givenname][0],
               last_name:   result[0][:sn][0],
               nickname:    result[0][:eduPersonNickname][0],
               # :phone     => result[0][:telephoneNumber][0],
               # Above line removed because the phone number in the Yale phonebook is always wrong
               username:       result[0][:uid][0],
               email:       result[0][:mail][0],
               affiliation: [result[0][:curriculumshortname],
                                result[0][:college],
                                result[0][:class]].select{ |s| s.length > 0 }.join(" ") }
    end
  end

  def self.search_ldap_email(email)
    # CODE TO SEARCH BY EMAIL HERE
  end

  def self.select_options
    User.order('last_name ASC').all.collect{ |item| ["#{item.last_name}, #{item.first_name}", item.id] }
  end

  def render_name
    ENV['CAS_AUTH'] ? "#{name} #{username}" : "#{name}"
  end


  # ---- Reservation methods ---- #

  def overdue_reservations?
    self.reservations.overdue.count > 0
  end

  def due_for_checkout
    self.reservations.checkoutable
  end

  def due_for_checkin
    self.reservations.checked_out.order('due_date ASC')
  end

end
