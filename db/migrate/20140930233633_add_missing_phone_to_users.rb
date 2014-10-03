class AddMissingPhoneToUsers < ActiveRecord::Migration
  def change
    add_column :users, :missing_phone, :boolean, default: false

    # go through existing users if require_phone is set to true and set
    # missing_phone appropriately
    if AppConfig.first.require_phone
      User.no_phone.update_all(missing_phone: true)
    end
  end
end
