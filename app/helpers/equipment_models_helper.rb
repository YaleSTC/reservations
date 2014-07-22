module EquipmentModelsHelper

  def evaluate_img_presence equipment_model
    if equipment_model.photo.exists?
      equipment_model.photo.url(:small)
    else
      "no-image-260.gif"
    end
  end

end
