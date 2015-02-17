class DeletedInput < SimpleForm::Inputs::BooleanInput
  def input
    build_check_box
  end

  def build_check_box(_unchecked_value = '')
    box_val =
      @builder.object.deleted_at.blank? ? { checked: false } : { checked: true }
    @builder.check_box(attribute_name,
                       box_val,
                       Time.zone.now, '')
  end
end
