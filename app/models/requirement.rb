class Requirement < ActiveRecord::Base
  has_many :equipment_models
  has_and_belongs_to_many :users,
                          :class_name => "User",
                          :association_foreign_key => "user_id",
                          :join_table => "users_requirements"
   attr_accessible :user_id, :equipment_model_id, :contact_info, :contact_name, :requirement_ids, :user_ids, :equipment_model_ids
   #serialize :requirement_steps

  validates :equipment_model_id, 
            :contact_info, 
            :contact_name, :presence => true


   #has_many :requirement_steps, :dependent => :destroy
   #accepts_nested_attributes_for :requirement_steps, :reject_if => :all_blank, :allow_destroy => true
   

#  def Requirement.get_all_ems_for_user(user)
#    a = []
#    MetRequirement.all.each{|metreq| a << metreq[:requirement_step_id] if metreq.user_id == user.id}
#    return a.each.map{|x| EquipmentModel.find(x).name}
#  end

#  def Requirement.get_users_with_permissions
#    a = []
#    MetRequirement.all.each{|metreq| a << metreq[:user_id]}
#    return a.uniq.collect{|x| User.find(x)}
#  end

#  def Requirement.get_steps_for_em
#    RequirementStep.all.where(:requirement_id => params[:requirement_id])
#  end

end
