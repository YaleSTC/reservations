class DeletedInput < SimpleForm::Inputs::BooleanInput
  def input
    build_check_box
  end
  
  def build_check_box(unchecked_value = "")
    @builder.check_box(attribute_name,  (@builder.object.deleted_at.blank? ? {:checked => false} : {:checked => true}), Time.now, "")
  end
end
