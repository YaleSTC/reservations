class CatalogController < ApplicationController
  def index
    @equipment_models_by_category = EquipmentModel.find(:all, :include => :category, :order => 'categories.name ASC, equipment_models.name ASC').group_by(&:category)
  end
end
