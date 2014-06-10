require 'net/ldap'

class User < ActiveRecord::Base
  has_many :reservations, foreign_key: 'reserver_id', dependent: :destroy
  nilify_blanks only: [:deleted_at]
  has_and_belongs_to_many :requirements,
                          class_name: "Requirement",
                          association_foreign_key: "requirement_id",
                          join_table: "users_requirements"

  attr_accessible :login, :first_name, :last_name, :nickname, :phone, :email,
                  :affiliation, :role, :view_mode, :created_by_admin,
                  :deleted_at, :requirement_ids, :user_ids, :terms_of_service_accepted, :csv_import

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
  scope :active, where("#{table_name}.deleted_at is null")

  # ------- validations -------- #
  def skip_phone_validation?
    if AppConfig.first          # is there an app config?
      if !AppConfig.first.require_phone
        return true             # if phone not required, return true
      else
        return ( @csv_import ? true : false ) # no phone required if csv
      end
    end
    return true                 # no phone required if no app config
  end
  # ------- end validations -------- #

  def name
    [((nickname.nil? || nickname.length == 0) ? first_name : nickname), last_name].join(" ")
  end

  def can_checkout?
    role == 'checkout' || self.is_admin?(as: 'admin') || self.is_admin?(as: 'checkout')
  end

  # if specified in appconfigs, these two methods will return true for checkout people. It will always return true for admins in admin mode
  def can_override_reservation_restrictions?
    return true if ( self.can_checkout? && AppConfig.first.override_on_create == true) or self.is_admin?(as: 'admin')
  end

  def can_override_checkout_restrictions?
    return true if ( self.can_checkout? && AppConfig.first.override_at_checkout == true ) or self.is_admin?(as: 'admin')
  end

  def is_admin?(options = {})
    if role == 'admin' || role == 'superuser'
      if options.empty? || options[:as] == view_mode
        return true
      end
    end
    return false
  end

  def equipment_objects
    self.reservations.collect{ |r| r.equipment_object }.flatten
  end

  # Returns hash of the checked out equipment models and their counts for the user
  def checked_out_models
    #Make a hash of the checked out eq. models and their counts for the user
    model_ids = self.reservations.collect do |r|
      if (!r.checked_out.nil? && r.checked_in.nil?) # i.e. if checked out but not checked in yet
        r.equipment_model_id
      end
    end

    #Remove nils, then count the number of unique model ids, and store the counts in a sub hash, and finally sort by model_id
    arr = model_ids.compact.inject(Hash.new(0)) {|h,x| h[x]+=1;h}.sort
    #Change into a hash of model_id => quantities
    Hash[*arr.flatten]

    #There might be a better way of doing this, but I realized that I wanted a hash instead of an array of hashes
  end

  def self.search_ldap(login)
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
    [((nickname.nil? || nickname.length == 0) ? first_name : nickname), last_name, login].join(" ")
  end

end
