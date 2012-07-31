class EquipmentModelsController < ApplicationController
  layout 'application_with_sidebar', only: :show

  before_filter :require_admin
  skip_before_filter :require_admin, :only => [:index, :show]

  require 'activationhelper'
  include ActivationHelper

  def index
    if params[:category_id]
      @category = Category.include_deleted.find(params[:category_id])
      @equipment_models = @category.equipment_models
    elsif params[:show_deleted]
      @equipment_models = EquipmentModel.include_deleted.find(:all, :include => :category, :order => 'categories.name ASC, equipment_models.name ASC')
    else
      @equipment_models = EquipmentModel.find(:all, :include => :category, :order => 'categories.name ASC, equipment_models.name ASC')
    end
  end

  def show
    @equipment_model = EquipmentModel.include_deleted.find(params[:id])
    @associated_equipment_models = @equipment_model.associated_equipment_models.sample(6)
  end

  def new
    @category = Category.include_deleted.find(params[:category_id]) if params[:category_id]
    @equipment_model = EquipmentModel.new(:category => @category)
  end

  def create
    @equipment_model = EquipmentModel.new(params[:equipment_model])
    if @equipment_model.save
      flash[:notice] = "Successfully created equipment model."
      redirect_to @equipment_model
    else
      flash[:error] = "Please review the errors below. "
      render :action => 'new'
    end
  end

  def edit
    @equipment_model = EquipmentModel.include_deleted.find(params[:id])
  end

  def update
    @equipment_model = EquipmentModel.include_deleted.find(params[:id])

    unless params[:clear_documentation].nil? # if we want to delete the current docs
      # recursively remove files from filesystem
      file_location = Rails.root.to_s + "/public/equipment_models/documentations/" + @equipment_model.id.to_s + "/"
      FileUtils.rm_r file_location
      @equipment_model.documentation_file_name = NIL
    end

    unless params[:clear_photo].nil? # if we want to delete the current photo
      # recursively remove files from filesystem
      file_location = Rails.root.to_s + "/public/equipment_models/photos/" + @equipment_model.id.to_s + "/"
      FileUtils.rm_r file_location
      @equipment_model.photo_file_name = NIL
    end

    if @equipment_model.update_attributes(params[:equipment_model])
      flash[:notice] = "Successfully updated equipment model."
      redirect_to @equipment_model
    else
      render :action => 'edit'
    end
  end

  def destroy
    @equipment_model = EquipmentModel.include_deleted.find(params[:id])
    @equipment_model.destroy(:force)
    flash[:notice] = "Successfully destroyed equipment model."
    redirect_to equipment_models_url
  end
end
