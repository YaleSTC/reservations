require 'net/ldap'

class User < ActiveRecord::Base
  has_many :reservations, :foreign_key => 'reserver_id'
  nilify_blanks :only => [:deleted_at] 
  has_and_belongs_to_many :requirements,
                          :class_name => "Requirement",
                          :association_foreign_key => "requirement_id",
                          :join_table => "users_requirements"

  attr_accessible :login, :first_name, :last_name, :nickname, :phone, :email,
                  :affiliation, :is_banned, :is_checkout_person, :is_admin,
                  :adminmode, :checkoutpersonmode, :normalusermode, :bannedmode, 
                  :deleted_at, :requirement_ids, :user_ids, :terms_of_service_accepted,
                  :created_by_admin

  attr_accessor   :full_query, :created_by_admin, :user_type, :csv_import

  validates :login,       :presence => true,
                          :uniqueness => true
  validates :first_name, 
            :last_name, 
            :affiliation, :presence => true
  validates :phone,       :presence    => true,
                          :format      => { :with => /\A\S[0-9\+\/\(\)\s\-]*\z/i },
                          :length      => { :minimum => 10 }, :unless => :skip_phone_validation?
  validates :email,       :presence    => true,
                          :format      => { :with => /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i }
  validates :nickname,    :format      => { :with => /^[^0-9`!@#\$%\^&*+_=]+$/ },
                          :allow_blank => true
  validates :terms_of_service_accepted,
                          :acceptance => {:accept => true, :message => "You must accept the terms of service."},
                          on: :create,
                          :if => Proc.new { |u| !u.created_by_admin == "true" }
                          
                          
                          

   default_scope where(:deleted_at => nil)
   
    def self.include_deleted
      self.unscoped
    end

  def name
     [((nickname.nil? || nickname.length == 0) ? first_name : nickname), last_name].join(" ")
  end
  
  def can_checkout?
    self.is_checkout_person? || self.is_admin_in_adminmode? || self.is_admin_in_checkoutpersonmode?
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
    self.reservations.collect{ |r| r.equipment_objects }.flatten
  end

  # Returns array of the checked out equipment models and their counts for the user
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
    ldap = Net::LDAP.new(:host => "directory.yale.edu", :port => 389)
    filter = Net::LDAP::Filter.eq("uid", login)
    attrs = ["givenname", "sn", "eduPersonNickname", "telephoneNumber", "uid",
             "mail", "collegename", "curriculumshortname", "college", "class"]
    result = ldap.search(:base => "ou=People,o=yale.edu", :filter => filter, :attributes => attrs)
    unless result.empty?
    return { :first_name  => result[0][:givenname][0],
             :last_name   => result[0][:sn][0],
             :nickname    => result[0][:eduPersonNickname][0],
             # :phone     => result[0][:telephoneNumber][0],
             # Above line removed because the phone number in the Yale phonebook is always wrong
             :login       => result[0][:uid][0],
             :email       => result[0][:mail][0],
             :affiliation => [result[0][:curriculumshortname],
                              result[0][:college],
                              result[0][:class]].select{ |s| s.length > 0 }.join(" ") }
    end
  end

  def self.select_options
    self.find(:all, :order => 'last_name ASC').collect{ |item| ["#{item.last_name}, #{item.first_name}", item.id] }
  end
  
  def render_name
     [((nickname.nil? || nickname.length == 0) ? first_name : nickname), last_name, login].join(" ")
  end
  
  def assign_type(user_type)
    # we have to reset all the non-current user_types to NIL
    # argh why is the database so stupid like this
    # with three columns where one would suffice

    if user_type == 'admin'
      self.is_admin = '1'
      self.is_checkout_person = nil
      self.is_banned = nil
    elsif user_type == 'checkout'
      self.is_admin = nil
      self.is_checkout_person = '1'
      self.is_banned = nil
    elsif user_type == 'normal'
      self.is_admin = nil
      self.is_checkout_person = nil
      self.is_banned = nil
    elsif user_type == 'banned'
      self.is_admin = nil
      self.is_checkout_person = nil
      self.is_banned = '1'
    end
  end
  
  def self.import_with_ldap(user_data_hash)
    # check LDAP for missing data
    ldap_user_hash = User.search_ldap(user_data_hash[:login])
    
    # if nothing found via LDAP
    if ldap_user_hash.nil?
      return
    end
    
    # fill-in missing key-values with LDAP data
    user_data_hash.keys.each do |key|
      if user_data_hash[key].blank? and !ldap_user_hash[key].blank?
        user_data_hash[key] = ldap_user_hash[key]
      end
    end
    user_data_hash
  end
  
  def self.import_users(array_of_user_data,update_existing = false,user_type = 'normal') # give safe defaults if none selected
    array_of_success = [] # will contain user-objects
    array_of_fail = [] # will contain user_data hashes and error messages

    array_of_user_data.each do |user_data|
      # test size == 1 in case the admin tries any funny business (non-uniqueness) in the database
      if update_existing and (User.where("login = ?", user_data[:login]).size == 1)
        user = User.where("login = ?", user_data[:login]).first
        user.csv_import = true

        if user.update_attributes(user_data)
          # assign type (isn't saved with update attributes, without adding to the user_data hash)
          user.assign_type(user_type)
          user.save
          # exit
          array_of_success << user
          next
        else
          ldap_hash = User.import_with_ldap(user_data)
          
          if ldap_hash # if LDAP lookup succeeded
            user_data = ldap_hash
          else # if LDAP lookup failed
            array_of_fail << [user_data, 'Incomplete user information. Unable to find user in online directory (LDAP).']
            next
          end
          
          # re-attempt save to database
          if user.update_attributes(user_data)
            # assign type (isn't saved with update attributes, without adding to the user_data hash)
            user.assign_type(user_type)
            user.save
            # exit
            array_of_success << user
            next
          else
            array_of_fail << [user_data, user.errors.full_messages.to_sentence]
            next
          end
        end
      else
        user = User.new(user_data)
        user.csv_import = true
        user.assign_type(user_type)
        
        if user.valid?
          user.save
          array_of_success << user
          next
        else
          ldap_hash = User.import_with_ldap(user_data)
          
          if ldap_hash # if LDAP lookup succeeded
            user_data = ldap_hash
          else # if LDAP lookup failed
            array_of_fail << [user_data, 'Incomplete user information. Unable to find user in online directory (LDAP).']
            next
          end
          
          # re-attempt save to database
          user = User.new(user_data)
          user.csv_import = true
          user.assign_type(user_type)
          
          if user.valid?
            user.save
            array_of_success << user
            next
          else
            array_of_fail << [user_data, user.errors.full_messages.to_sentence.capitalize + '.']
            next
          end
        end
      end
    end
    hash_of_statuses = {:success => array_of_success, :fail => array_of_fail}
  end

  def skip_phone_validation?
    csv_import
  end

  #TODO: investigate why this is necessary; change to SQL
  def reservations_array
    reservations = []
    Reservation.all.each { |res| reservations << res if res.reserver = self }
    reservations
  end

end
