class Requirement < ActiveRecord::Base
   belongs_to :equipment_model
   attr_accessible :user_id, :equipment_model_id, :contact_info, :requirement_steps_attributes
   serialize :requirement_steps

   has_many :requirement_steps, :dependent => :destroy
   accepts_nested_attributes_for :requirement_steps, :reject_if => :all_blank, :allow_destroy => true
   

  def Requirement.get_all_ems_for_user(user)
    a = []
    MetRequirement.all.each{|metreq| a << metreq[:requirement_step_id] if metreq.user_id == user.id}
    return a.each.map{|x| EquipmentModel.find(x).name}
  end

  def Requirement.get_users_with_permissions
    a = []
    MetRequirement.all.each{|metreq| a << metreq[:user_id]}
    return a.uniq.collect{|x| User.find(x)}
  end

  def Requirement.get_steps_for_em
    binding.pry
    RequirementStep.all.where(:requirement_id => params[:requirement_id])
  end
end
