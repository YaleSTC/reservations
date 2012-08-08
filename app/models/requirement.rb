class Requirement < ActiveRecord::Base
  has_and_belongs_to_many :equipment_models
  has_and_belongs_to_many :users,
                          :class_name => "User",
                          :association_foreign_key => "user_id",
                          :join_table => "users_requirements" # This join table associates users with the requirements that they have fulfilled. To give a user permission to reserve an item with a requirement, go to their Edit page.
   attr_accessible :user_id, :description, :equipment_model_id, :contact_info, :contact_name, :requirement_ids, :user_ids, :equipment_model_ids, :notes
   #serialize :requirement_steps

  validates :contact_info, 
            :description,
            :contact_name, :presence => true


def self.list_requirement_admins(current_user, equipment_model)
  req_status = ""
  met_reqs = (equipment_model.requirements & current_user.requirements)
  outstanding_reqs = equipment_model.requirements - met_reqs
  admin_names = outstanding_reqs.collect{|req| req.contact_name}.to_sentence
  admin_contacts = outstanding_reqs.collect{|req| req.contact_info}.to_sentence
  unless met_reqs.empty?
    met_admin_names = met_reqs.collect{|req| req.contact_name}.to_sentence
    req_status += "You have already met the requirements to check out this model set by " + met_admin_names + ". However, this model requires additional training before it can be reserved. "
  else
    req_status += "This model requires proper training before it can be reserved. "
  end
  # this is currently returning all names, then all email addresses, in one sentence
  req_status += "Please contact " + admin_names + " at " + admin_contacts + " about becoming certified."
end

# This code is all related to creating requirements that have multi-step qualification processes, such as a long training program. The code is not necessary for Reservations as-is, but may be useful in future upgrades!

   #has_many :requirement_steps, :dependent => :destroy
   #accepts_nested_attributes_for :requirement_steps, :reject_if => :all_blank, :allow_destroy => true
#   
#
#  def Requirement.get_all_ems_for_user(user)
#    a = []
#    MetRequirement.all.each{|metreq| a << metreq[:requirement_step_id] if metreq.user_id == user.id}
#    return a.each.map{|x| EquipmentModel.find(x).name}
#  end
#
#  def Requirement.get_users_with_permissions
#    a = []
#    MetRequirement.all.each{|metreq| a << metreq[:user_id]}
#    return a.uniq.collect{|x| User.find(x)}
#  end
#
#  def Requirement.get_steps_for_em
#    RequirementStep.all.where(:requirement_id => params[:requirement_id])
#  end

end
