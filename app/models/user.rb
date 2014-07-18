require 'net/ldap'

class User < ActiveRecord::Base
  has_many :reservations, foreign_key: 'reserver_id', dependent: :destroy
  has_and_belongs_to_many :requirements,
                          class_name: "Requirement",
                          association_foreign_key: "requirement_id",
                          join_table: "users_requirements"

  attr_accessible :login, :first_name, :last_name, :nickname, :phone, :email,
                  :affiliation, :role, :view_mode, :created_by_admin,
                  :requirement_ids, :user_ids, :terms_of_service_accepted, :csv_import

  attr_accessor   :full_query, :created_by_admin, :user_type, :csv_import

  validates :login,       presence: true,
                          uniqueness: true
  validates :first_name,
            :last_name,
            :affiliation, presence: true
  validates :phone,       presence:    true,
                          format:      { with: /\A\S[0-9\+\/\(\)\s\-]*\z/i },
                          length:      { minimum: 10 }, unless: lambda {|x| x.skip_phone_validation?}

  validates :email,       presence:    true,
                          format:      { with: /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i }
  validates :nickname,    format:      { with: /^[^0-9`!@#\$%\^&*+_=]+$/ },
                          allow_blank: true
  validates :terms_of_service_accepted,
                          acceptance: {accept: true, message: "You must accept the terms of service."},
                          on: :create,
                          if: Proc.new { |u| !u.created_by_admin == "true" }
  validates :role,
            :view_mode,   inclusion: { in: ['admin', 'normal', 'checkout', 'superuser', 'banned'] }

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, where("role != 'banned'")

  # ------- validations -------- #
  def skip_phone_validation?
    return true unless AppConfig.first
    return true unless AppConfig.first.require_phone
    return !@csv_import.nil?
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
               login:       result[0][:uid][0],
               email:       result[0][:mail][0],
               affiliation: [result[0][:curriculumshortname],
                                result[0][:college],
                                result[0][:class]].select{ |s| s.length > 0 }.join(" ") }
    end
  end

  def self.select_options
    self.find(:all, order: 'last_name ASC').collect{ |item| ["#{item.last_name}, #{item.first_name}", item.id] }
  end

  def render_name
    "#{name} #{login}"
  end


  # ---- Reservation methods ---- #

  def overdue_reservations?
    self.reservations.overdue.count > 0
  end

  def due_for_checkout
    self.reservations.upcoming
  end

  def due_for_checkin
    self.reservations.checked_out.order('due_date ASC')
  end

end
