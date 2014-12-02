require 'net/ldap'

class User < ActiveRecord::Base
  include Routing

  # Include authentication modules
  # If the CAS_AUTH environment variable is set, we simply include the
  # :cas_authenticatable module. If not, we implement password authentcation
  # using the :database_authenticatable module and also allow for password
  # resets.
  if ENV['CAS_AUTH']
    devise :cas_authenticatable
  else
    devise :database_authenticatable, :recoverable
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
  # validations for password authentication
  unless ENV['CAS_AUTH']
    # only run password validatons if the parameter is present
    validates :password,  presence: true,
                          length: { minimum: 8 }, :unless => lambda {|u| u.password.nil? }
    # check password confirmations
    validates_confirmation_of :password, only: :create
  end
  validates :nickname,    format:      { with: /\A[^0-9`!@#\$%\^&*+_=]+\z/ },
                          allow_blank: true
  validates :terms_of_service_accepted,
                          acceptance: {accept: true, message: "You must accept the terms of service."},
                          on: :create,
                          if: Proc.new { |u| !u.created_by_admin == "true" }
  roles = ['admin', 'normal', 'checkout', 'superuser', 'banned']
  validates :role,        inclusion: { in: roles }
  validates :view_mode,   inclusion: { in: roles << 'guest' }
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
    return nil unless ENV['USE_LDAP']
    if ENV['CAS_AUTH']
      filter_param = Rails.application.secrets.ldap_login
    else
      filter_param = Rails.application.secrets.ldap_email
    end

    ldap = Net::LDAP.new(host: "directory.yale.edu", port: 389)
    filter = Net::LDAP::Filter.eq(filter_param, login)
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

  def self.select_options
    User.order('last_name ASC').all.collect{ |item| ["#{item.last_name}, #{item.first_name}", item.id] }
  end

  def render_name
    ENV['CAS_AUTH'] ? "#{name} #{username}" : "#{name}"
  end

  def md_link
    "[#{self.name}](#{user_url(self, only_path: false)})"
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
