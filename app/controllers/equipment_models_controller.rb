class EquipmentModelsController < ApplicationController
  layout 'application_with_sidebar', only: :show

  before_filter :require_admin
  before_filter :set_equipment_model, only: [:show, :edit, :update, :destroy]
  skip_before_filter :require_admin, only: [:index, :show]
  before_filter :set_category_if_possible, only: [:index, :new]

  include EquipmentModelsHelper

  # --------- before filter methods --------- #
  def set_equipment_model
    @equipment_model = EquipmentModel.find(params[:id])
  end
  def set_category_if_possible
    @category = Category.find(params[:category_id]) if params[:category_id]
  end
  # --------- end before filter methods --------- #


  def index
    if params[:show_deleted]
      @equipment_models = ( @category ? @category.equipment_models : EquipmentModel.all )
    else
      @equipment_models = ( @category ? @category.equipment_models.active : EquipmentModel.active )
    end
  end

  def show
    @associated_equipment_models = @equipment_model.associated_equipment_models.sample(6)
  end

  def new
    @equipment_model = EquipmentModel.new(category: @category)
  end

  def create
    @equipment_model = EquipmentModel.new(params[:equipment_model])
    if @equipment_model.save
      flash[:notice] = "Successfully created equipment model."
      redirect_to @equipment_model
    else
      flash[:error] = "Please review the errors below. "
      render action: 'new'
    end
  end

  def edit
  end

  def delete_files
    # for a given filetype affected by param value, the file in question is saved in path contained value
    types = {"clear_documentation" => "documentations", "clear_photo" => "photos"}

    # only keep pairs that occur as keys with non-nil values in params
    types.select! {|k,v| params.keys.member? (k) and !v.nil?}
    types.each do |k,path|
      # TODO: investigate a way to do this without hard-coded paths
      # recursively remove files from filesystem
      file_location = Rails.root.to_s + "/public/attachments/equipment_models/" + path + "/" + @equipment_model.id.to_s + "/original/"
      FileUtils.rm_r file_location
      @equipment_model.documentation_file_name = NIL
    end
  end

  def update
    delete_files
    if @equipment_model.update_attributes(params[:equipment_model])
      # hard-delete any deleted checkin/checkout procedures
      delete_procedures(params, "checkout")
      delete_procedures(params, "checkin")
      flash[:notice] = "Successfully updated equipment model."
      redirect_to @equipment_model
    else
      render action: 'edit'
    end
  end

  def destroy
    @equipment_model.destroy(:force)
    flash[:notice] = "Successfully destroyed equipment model."
    redirect_to equipment_models_url
  end
end
