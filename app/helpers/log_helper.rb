module LogHelper
  # Expects an array where `arr[0]` is hash key and `arr[1]` the hash value
  # -- in other words, an element of an array returned by `object.attributes`.

  # Returns a sanitized two-item array, or false if the row should be omitted.
  def transform_attributes(arr)
    key_dict = {"id" => "Reservation ID",
                "reserver_id" => "Patron",
                "checkout_handler_id" => "Checkout Person",
                "checkin_handler_id" => "Checkin Person",
                "notes_unsent" => "Notes Sent to Patron?"}
    unless key_dict.include? arr[0]
      key = arr[0].split("_").map(&:capitalize).join(' ')
      key.sub! "Id", "ID"
    else
      key = key_dict[arr[0]]
    end

    val_dict = {"id" => Proc.new { |id| get_reservation_link(id) },
                "reserver_id" => Proc.new { |id| get_user_link(id) },
                "checkout_handler_id" => Proc.new { |id| get_user_link(id) },
                "checkin_handler_id" => Proc.new { |id| get_user_link(id) },
                "equipment_model_id" => Proc.new { |id| get_model_link(id) },
                "equipment_object_id" => Proc.new { |id| get_object_link(id) }
              }

    if arr[1].nil?
      val = "N/A"
    elsif val_dict.has_key? arr[0]
      val = val_dict[arr[0]].call arr[1]
    else
      val = arr[1]
    end

    return [key, val]
  end

  def get_reservation_link(res_id)
    res = Reservation.find_by_id(res_id)
    if res.nil?
      return "#{res_id} (deleted)"
    else
      return link_to "#{res_id} (see current)", res
    end
  end

  def get_model_link(em_id)
    model = EquipmentModel.find_by_id(em_id)
    return link_to model.name, model
  end

  def get_object_link(obj_id)
    object = EquipmentObject.find_by_id(obj_id)
    if object.nil?
      return "N/A"
    else
      return link_to object.name, object
    end
  end

  def get_user_link(user_id)
    if user_id.nil?
      return "N/A"
    end

    user = User.find_by_id(user_id)
    if user.nil?
      return "N/A"
    end

    return link_to user.name, user
  end
end
