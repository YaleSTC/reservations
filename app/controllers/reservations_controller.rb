class ReservationsController < ApplicationController
  before_filter :require_login, :only => [:index, :show]
  before_filter :require_admin, :only => [:check_out, :check_in]
  
  def index
    if current_user.is_admin?
      @reservations = Reservation.all
    else
      @reservations = current_user.reservations
    end
  end
  
  def show
    @reservation = Reservation.find(params[:id])
  end
  
  def new
    if cart.items.empty?
      flash[:error] = "You need to add items to your cart before making a reservation!"
      redirect_to catalog_path
    else
      @reservation = Reservation.new
      @reservation.start_date = cart.start_date
      @reservation.due_date = cart.due_date
    end
  end
  
  def create
    @reservation = Reservation.new(params[:reservation])
    cart.items.each do |item|
      @reservation.equipment_models_reservations << EquipmentModelsReservation.new(:equipment_model_id => item.equipment_model.id, :quantity => item.quantity)
    end
    if @reservation.save
      flash[:notice] = "Successfully created reservation."
      session[:cart] = Cart.new
      redirect_to @reservation
    else
      render :action => 'new'
    end
  end
  
  def edit
    @reservation = Reservation.find(params[:id])
  end
  
  def update
    @reservation = Reservation.find(params[:id])

    if params[:commit] == "Check out equipment"
      @reservation.checked_out = Time.now
      # if equipment object ids are not unique, throw a hissy fit
      if params[:reservation][:equipment_object_ids].uniq!
        flash.now[:error] = "The same piece of equipment cannot be assigned twice!"
        render :action => 'check_out' and return 
      end
    elsif params[:commit] == "Check in equipment"
      @reservation.checked_in = Time.now
      # if not all objects are returned, throw up a warning
      if params[:reservation][:equipment_object_ids].size != @reservation.equipment_objects.size
        flash[:error] = "However, you must return all equipment to complete check-in!" 
      end
      #return the checked off items
      params[:reservation][:equipment_object_ids] = @reservation.equipment_objects.collect{|e| e.id.to_s} - params[:reservation][:equipment_object_ids]
    end

    if @reservation.update_attributes(params[:reservation])
      flash[:notice] = "Successfully updated reservation."
      redirect_to @reservation
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @reservation = Reservation.find(params[:id])
    require_user(@reservation.user)
    @reservation.destroy
    flash[:notice] = "Successfully destroyed reservation."
    redirect_to reservations_url
  end
  
  def check_out
    @reservation = Reservation.find(params[:id])
  end
  
  def check_in
    @reservation = Reservation.find(params[:id])
  end
end
