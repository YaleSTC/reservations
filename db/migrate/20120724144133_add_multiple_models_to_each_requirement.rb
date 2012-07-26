class AddMultipleModelsToEachRequirement < ActiveRecord::Migration
  def change
    create_table :equipment_models_requirements, :id => false do |t|
    t.references :requirement, :null => false
    t.references :equipment_model, :null => false
   end
  end
end