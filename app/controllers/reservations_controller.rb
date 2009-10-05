class ReservationsController < ApplicationController
  def index
    @reservations = Reservation.all
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
    if @reservation.update_attributes(params[:reservation])
      flash[:notice] = "Successfully updated reservation."
      redirect_to @reservation
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @reservation = Reservation.find(params[:id])
    @reservation.destroy
    flash[:notice] = "Successfully destroyed reservation."
    redirect_to reservations_url
  end
end
