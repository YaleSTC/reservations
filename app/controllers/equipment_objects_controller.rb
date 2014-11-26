class EquipmentObjectsController < ApplicationController
  load_and_authorize_resource
  before_action :set_current_equipment_object, only: [:show, :edit, :update, :destroy, :deactivate, :activate]
  before_action :set_equipment_model_if_possible, only: [:index, :new]

  include ActivationHelper

  # ---------- before filter methods ---------- #

  def set_current_equipment_object
    @equipment_object = EquipmentObject.find(params[:id])
  end

  def set_equipment_model_if_possible
    @equipment_model = EquipmentModel.find(params[:equipment_model_id]) if params[:equipment_model_id]
  end

  # ---------- end before filter methods ---------- #

  #I'm not sure if there's ever a way @equipment_model could be set?
  def index
    if params[:show_deleted]
      @equipment_objects = ( @equipment_model  ? @equipment_model.equipment_objects : EquipmentObject.all )
    else
      @equipment_objects = ( @equipment_model  ? @equipment_model.equipment_objects.active : EquipmentObject.active )
    end
  end

  def show
  end

  def new
    @equipment_object = EquipmentObject.new(equipment_model: @equipment_model)
  end

  def create
    @equipment_object = EquipmentObject.new(equipment_object_params)
    @equipment_object.notes = "#### Created at #{Time.current.to_s(:long)} by #{current_user.md_link}"
    if @equipment_object.save
      flash[:notice] = "Successfully created equipment object. #{@equipment_object.serial}"
      redirect_to @equipment_object.equipment_model
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    p = equipment_object_params
    if p[:deleted_at].blank?
      # Delete deactivation reason when "Disabled?" is toggled
      p[:deactivation_reason] = ""
    end
    @equipment_object.update(current_user, p)
    if @equipment_object.save
      flash[:notice] = "Successfully updated equipment object."
      redirect_to @equipment_object
    else
      render action: 'edit'
    end
  end

  # Deactivate and activate extend controller methods in ApplicationController
  def deactivate
    if params[:deactivation_reason] && !params[:deactivation_cancelled]
      # update notes and deactivate
      new_notes = "#### Deactivated at #{Time.current.to_s(:long)} by #{current_user.md_link}\n#{params[:deactivation_reason]}\n\n" + @equipment_object.notes
      @equipment_object.update_attributes(deactivation_reason: params[:deactivation_reason], notes: new_notes)
      # archive current reservation if any
      @equipment_object.current_reservation.archive(current_user, "The equipment item was deactivated for the following reason: **#{params[:deactivation_reason]}**").save(validate: false) if @equipment_object.current_reservation
      super
    elsif params[:deactivation_cancelled]
      flash[:notice] = "Deactivation cancelled."
      redirect_to @equipment_object.equipment_model
    else
      flash[:error] = 'Please enter a deactivation reason.'
      redirect_to @equipment_object.equipment_model
    end
  end

  def activate
    super
    new_notes = "#### Reactivated at #{Time.current.to_s(:long)} by #{current_user.md_link}\n\n" + @equipment_object.notes
    @equipment_object.update_attributes(deactivation_reason: nil, notes: new_notes)
  end

  private

  def equipment_object_params
    params.require(:equipment_object).permit(:name, :serial, :deleted_at,
                                             :equipment_model_id,
                                             :deactivation_reason, :notes)
  end

  def make_deactivate_btn(model_symbol, model_object)
    binding.pry
    unless model_object.deleted_at
      em = model_object.equipment_model
      # look for current reservation
      res = model_object.current_reservation
      overbooked_dates = []
      # check to see if it will be overbooked in the next week
      for date in Date.current..Date.current+7.days
        overbooked_dates << date.to_s(:short) if em.available_count(date) <= 0
      end
      onclick_str = "handleDeactivation(this, #{res ? res.id : 'null'}, #{overbooked_dates});"
    end
    super
  end
end
