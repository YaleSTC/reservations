class AddRequirePhoneToUsers < ActiveRecord::Migration
  def change
    add_column :users, :missing_phone, :boolean, default: false

    # go through existing users if require_phone is set to true and set
    # missing_phone appropriately
    if AppConfig.first.require_phone
      User.where("phone = ? OR phone IS NULL", '').each do |user|
        user.missing_phone = true
        user.save
      end
    end
  end
end
