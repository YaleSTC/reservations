class AddDescriptionToRequirements < ActiveRecord::Migration
  def change
    add_column :requirements, :description, :string
  end
end
