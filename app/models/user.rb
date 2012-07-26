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
  
  
  def self.csv_import(location)
    # initialize
    users_hash = {}
    require 'csv'
    
    # import data by row
    CSV.foreach(location) do |row|
    
      # make sure CSV has the proper number of columns
      if row.size < 7
        return
      end
      
      # make sure nil entries are blank
      blankified_row = []
      row.each do |e|
        if e.nil?
          e = ''
        end
        blankified_row << e
      end
      row = blankified_row
      
      # order of variables: login, first_name, last_name, nickname, phone, email, affiliation
      users_hash[row[0]] = [row[1], row[2], row[3], row[4], row[5], row[6]]
    end
    
    # return users hash
    users_hash
  end

  def self.csv_data_formatting(user,data,user_type)
    hash = {}
    hash[:login] = user
    hash[:first_name] = data[0]
    hash[:last_name] = data[1]
    hash[:nickname] = data[2]
    hash[:phone] = data[3]
    hash[:email] = data[4]
    hash[:affiliation] = data[5]
#    hash[:csv_import] = true # attr_accessor defined above
    
    if user_type == 'admin'
      hash[:is_admin] = 1
    elsif user_type == 'checkout'
      hash[:is_checkout_person] = 1
    #elsif user_type == 'normal'
      # add something if we change how type is stored in the database
    elsif user_type == 'banned'
      hash[:is_banned] = 1
    end

    # return
    hash
  end

  def skip_phone_validation?
    csv_import
  end

  def self.import_ldap_fix(ldap_hash,user,data,user_type)
    ldap_hash[:login] = user
    ldap_hash[:first_name] = data[0] unless data[0].blank?
    ldap_hash[:last_name] = data[1] unless data[1].blank?
    if ldap_hash[:nickname].nil? or !data[2].blank?
      ldap_hash[:nickname] = data[2] # never want NIL nickname -- better to have blank
    end
    ldap_hash[:phone] = data[3] # LDAP doesn't fetch phone number
    ldap_hash[:email] = data[4] unless data[4].blank?
    ldap_hash[:affiliation] = data[5] unless data[5].blank?
#    ldap_hash[:csv_import] = true # attr_accessor defined above
    
    if user_type == 'admin'
      ldap_hash[:is_admin] = 1
    elsif user_type == 'checkout'
      ldap_hash[:is_checkout_person] = 1
    #elsif user_type == 'normal'
      # add something if we change how type is stored in the database
    elsif user_type == 'banned'
      ldap_hash[:is_banned] = 1
    end

    # return
    ldap_hash
  end
  
end
