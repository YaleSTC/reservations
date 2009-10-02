class ReservationsController < ApplicationController
  def index
    @reservations = Reservation.all
  end
  
  def show
    @reservation = Reservation.find(params[:id])
  end
  
  def new
    @reservation = Reservation.new
  end
  
  def create
    @reservation = Reservation.new(params[:reservation])
    if @reservation.save
      flash[:notice] = "Successfully created reservation."
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
