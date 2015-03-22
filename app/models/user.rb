require 'net/ldap'

# rubocop:disable ClassLength
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
                          class_name: 'Requirement',
                          association_foreign_key: 'requirement_id',
                          join_table: 'users_requirements'

  attr_accessor :full_query, :created_by_admin, :user_type, :csv_import

  validates :username,    presence: true,
                          uniqueness: true
  validates :first_name,
            :last_name,
            :affiliation, presence: true
  validates :phone, presence: true,
                    format: { with: /\A\S[0-9\+\/\(\)\s\-]*\z/i },
                    length: { minimum: 10 },
                    unless: ->(u) { u.skip_phone_validation? }

  validates :email,
            presence: true, uniqueness: true,
            format: { with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i }
  # validations for password authentication
  unless ENV['CAS_AUTH']
    # only run password validatons if the parameter is present
    validates :password,  presence: true,
                          length: { minimum: 8 },
                          unless: ->(u) { u.password.nil? }
    # check password confirmations
    validates :password, confirmation: :true, on: [:create, :update]
  end
  validates :nickname,    format:      { with: /\A[^0-9`!@#\$%\^&*+_=]+\z/ },
                          allow_blank: true
  validates :terms_of_service_accepted,
            acceptance: { accept: true,
                          message: 'You must accept the terms of service.' },
            on: :create,
            if: proc { |u| !u.created_by_admin == 'true' }
  roles = %w(admin normal checkout superuser banned)
  validates :role,        inclusion: { in: roles }
  validates :view_mode,   inclusion: { in: roles << 'guest' }
  validate :view_mode_reset

  # table_name is needed to resolve ambiguity for certain queries with
  # 'includes'
  scope :active, ->() { where("role != 'banned'") }
  scope :no_phone, ->() { where('phone = ? OR phone IS NULL', '') }

  # ------- validations -------- #
  def skip_phone_validation?
    return true unless AppConfig.check(:require_phone)
    return true if missing_phone
    !@csv_import.nil?
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

  def equipment_items
    reservations.collect(&:equipment_item).flatten
  end

  # rubocop:disable AbcSize, MethodLength, PerceivedComplexity
  def self.search_ldap(login)
    return nil if login.blank?
    return nil unless ENV['USE_LDAP']

    if ENV['CAS_AUTH']
      filter_param = Rails.application.secrets.ldap_login
    else
      filter_param = Rails.application.secrets.ldap_email
    end

    # set up LDAP object and filter parameters
    ldap = Net::LDAP.new(host: Rails.application.secrets.ldap_host,
                         port: Rails.application.secrets.ldap_port)
    filter = Net::LDAP::Filter.eq(filter_param, login)

    # set up attributes hash based on configuration
    attrs = [Rails.application.secrets.ldap_login,
             Rails.application.secrets.ldap_email,
             Rails.application.secrets.ldap_first_name,
             Rails.application.secrets.ldap_last_name,
             Rails.application.secrets.ldap_nickname]

    # actually look up query
    result = ldap.search(base: Rails.application.secrets.ldap_base,
                         filter: filter,
                         attributes: attrs)

    unless result.empty?
      # store output hash
      out = {}
      out[:first_name] =
        result[0][Rails.application.secrets.ldap_first_name.to_sym][0]
      out[:last_name] =
        result[0][Rails.application.secrets.ldap_last_name.to_sym][0]
      out[:nickname] =
        result[0][Rails.application.secrets.ldap_nickname.to_sym][0]
      out[:email] =
        result[0][Rails.application.secrets.ldap_email.to_sym][0]

      # define username based on authentication method
      if ENV['CAS_AUTH']
        out[:username] =
          result[0][Rails.application.secrets.ldap_login.to_sym][0]
      else
        out[:username] = out[:email]
      end

      # return hash
      return out
    end
  end
  # rubocop:enable AbcSize, MethodLength, PerceivedComplexity

  def self.select_options
    User.order('last_name ASC').all
      .collect { |item| ["#{item.last_name}, #{item.first_name}", item.id] }
  end

  def render_name
    ENV['CAS_AUTH'] ? "#{name} #{username}" : "#{name}"
  end

  def md_link
    "[#{name}](#{user_url(self, only_path: false)})"
  end

  # ---- Reservation methods ---- #

  def overdue_reservations?
    reservations.overdue.count > 0
  end

  def due_for_checkout
    reservations.checkoutable
  end

  def due_for_checkin
    reservations.checked_out.order('due_date ASC')
  end
end
