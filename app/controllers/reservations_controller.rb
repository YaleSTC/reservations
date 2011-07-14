class ReservationsController < ApplicationController
  before_filter :require_login, :only => [:index, :show]
  before_filter :require_checkout_person, :only => [:check_out, :check_in]

  def index
    if current_user.can_checkout?
      if params[:show_returned]
        @reservations_set = [Reservation.overdue, Reservation.checked_out, Reservation.pending, Reservation.returned ].delete_if{|a| a.empty?} #remove empty arrays from set
      else
        @reservations_set = [Reservation.overdue, Reservation.checked_out, Reservation.pending ].delete_if{|a| a.empty?}
      end
    else
      @reservations = current_user.reservations.sort_by(&:start_date).reverse
    end
  end

  def show
    @reservation = Reservation.find(params[:id])
  end

  def show_all
    @user = User.find(params[:id])
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

  # def create
  #   @reservation = Reservation.new(params[:reservation])
  #   cart.items.each do |item|
  #     @reservation.equipment_models_reservations << EquipmentModelsReservation.new(:equipment_model_id => item.equipment_model.id, :quantity => item.quantity)
  #   end
  #   if @reservation.save
  #     flash[:notice] = "Successfully created reservation."
  #     session[:cart] = Cart.new
  #     redirect_to @reservation
  #   else
  #     render :action => 'new'
  #   end
  # end

  def create
    cart.items.each do |item|
      for q in 1..item.quantity     # accounts for reserving multiple equipment objects of the same equipment model (mainly for admins)
        @reservation = Reservation.new(params[:reservation])
        @reservation.equipment_model =  item.equipment_model
        @reservation.save
      end
    end
    flash[:notice] = "Your reservations have been made."
    session[:cart] = Cart.new
    redirect_to catalog_path
  rescue
    flash.now[:error] = "Oops, something went wrong with making your reservation."
  end


  def edit
    @reservation = Reservation.find(params[:id])
  end

  def update

    @reservation = Reservation.find(params[:id])

    if params[:commit] == "Check out equipment"
      #update attributes for all equipment that is checked off
      reservations_to_be_checked_out = []
      reservation_check_out_procedures_count = []
      params[:reservations].each do |reservation_id, reservation_hash|
        if reservation_hash[:checkout?] == "1" then
          r = Reservation.find(reservation_id)
          r.checkout_handler = current_user
          r.checked_out = Time.now
          r.equipment_object = EquipmentObject.find(reservation_hash[:equipment_object_id])
          reservations_to_be_checked_out << r
          #There is no editable "checkout procedures" attribute for reservations. Ideally, this coding will be improved so that each individual procedure is considered and recorded. For now, we're just making sure that all procedures are checked off.
          reservation_check_out_procedures_count << (reservation_hash[:checkout_procedures] || []).count
        end
      end

      #All-encompassing checks
      if reservations_to_be_checked_out.first.nil?
        flash[:error] = "No reservation selected!"
        redirect_to :action => 'check_out' and return
      elsif Reservation.overdue_reservations?(reservations_to_be_checked_out.first.reserver)
        flash[:error] = "User has overdue equipment, checkout may not proceed"
        redirect_to :action => "check_out" and return
      end

      #Checks that must be done on each individual reservation
      error_msg = reservations_to_be_checked_out.first.check_out_permissions(reservations_to_be_checked_out, reservation_check_out_procedures_count)
      if !error_msg.empty?
        flash[:error] = error_msg
        redirect_to :action => 'check_out' and return
      else
        reservations_to_be_checked_out.each do |reservation|
          reservation.save
        end
        flash[:notice] = "Successfully checked out equipment!"
        redirect_to :action => 'index' and return
      end


    elsif params[:commit] == "Check in equipment"

      if params[:reservations].nil?
        flash[:error] = "No reservation selected!"
        redirect_to :action => 'check_in' and return
      end

      reservations_to_be_checked_in = []
      reservation_check_in_procedures_count = []
      params[:reservations].each do |reservation_id, reservation_hash|
        if reservation_hash[:checkin?] == "1"  then
          r = Reservation.find(reservation_id)
          r.checkin_handler = current_user
          r.checked_in = Time.now
          reservations_to_be_checked_in << r
          reservation_check_in_procedures_count << (reservation_hash[:checkin_procedures] || []).count
        else
          flash[:error] = "You filled out check in procedures without selecting the reservation!"
          redirect_to :action => 'check_in' and return
        end
      end

      error_msg = reservations_to_be_checked_in.first.check_in_permissions(reservations_to_be_checked_in, reservation_check_in_procedures_count)
      if !error_msg.empty?
        flash[:error] = error_msg
        redirect_to :action => 'check_in' and return
      else
        reservations_to_be_checked_in.each do |reservation|
          reservation.save
        end
        flash[:notice] = "Successfully checked in equipment!"
        redirect_to :action => 'index' and return
      end

      if params[:commit] == "Submit"
        if @reservation.update_attributes(params[:reservation])
          flash[:notice] = "Successfully edited reservation."
          redirect_to @reservation
        end
      end
    end
  end

  def destroy
    @reservation = Reservation.find(params[:id])
    require_user_or_checkout_person(@reservation.reserver)
    @reservation.destroy
    flash[:notice] = "Successfully destroyed reservation."
    redirect_to reservations_url
  end

  def check_out
    @reservation = Reservation.find(params[:id])
    @check_out_set = Reservation.due_for_checkout(@reservation.reserver)
  end

  def check_in
    @reservation = Reservation.find(params[:id])
    @check_in_set = Reservation.due_for_checkin(@reservation.reserver)
  end


end

