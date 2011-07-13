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
#    raise params.to_yaml
    @reservation = Reservation.find(params[:id])

    if params[:commit] == "Check out equipment"
      reservations_to_be_checked_out = []
      reservation_check_out_procedures_count = []
      params[:reservations].each do |reservation_id, reservation_hash|
        if reservation_hash[:checkout?] == "1" then
          r = Reservation.find(reservation_id)
          r.checkout_handler = current_user
          r.checked_out = Time.now
          r.equipment_object = EquipmentObject.find(reservation_hash[:equipment_object_id])
          reservations_to_be_checked_out << r
          if reservation_hash[:checkout_procedures]
            reservation_check_out_procedures_count << reservation_hash[:checkout_procedures].count
          else
            reservation_check_out_procedures_count << 0
          end
        end
      end

      a_reservation = Reservation.find(params[:reservations].first.first)
      if reservations_to_be_checked_out.first.nil?
        flash[:error] = "No reservation selected!"
        redirect_to :action => 'check_out' and return
      end

      error_msg = a_reservation.check_for_validity(reservations_to_be_checked_out)
      if Reservation.overdue_reservations?(a_reservation.reserver)
        flash[:error] = "User has overdue equipment, checkout may not proceed"
        redirect_to :action => "check_out" and return
      elsif !error_msg.empty?
        flash[:error] = error_msg
        redirect_to :action => 'check_out' and return
      elsif error_msg.empty?
        hash = Hash[reservations_to_be_checked_out.zip(reservation_check_out_procedures_count)]
        hash.each do |reservation, count|
         if !reservation.equipment_model.checkout_procedures.nil?
            if reservation.equipment_model.checkout_procedures.count != count
              flash[:error] = "Checkout Procedures for #{reservation.equipment_model.name} not Completed"
              redirect_to :action => 'check_out' and return
            end
          end
          reservation.save
        end
      end
        flash[:notice] = "Successfully checked out equipment!"
        redirect_to :action => 'index' and return


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
          if reservation_hash[:checkin_procedures]
            reservation_check_in_procedures_count << reservation_hash[:checkin_procedures].count
          else
            reservation_check_in_procedures_count << 0
          end
        end
      end

      hash = Hash[reservations_to_be_checked_in.zip(reservation_check_in_procedures_count)]
      hash.each do |reservation, count|
        if !reservation.equipment_model.checkin_procedures.nil?
          if reservation.equipment_model.checkin_procedures.count != count
            flash[:error] = "Checkin Procedures for #{reservation.equipment_model.name} not Completed"
            redirect_to :action => 'check_in' and return
          end
        end
          reservation.save
      end
      flash[:notice] = "Successfull checked in equipment"
      redirect_to :action => 'index' and return
    end

    if params[:commit] == "Submit"
      if @reservation.update_attributes(params[:reservation])
        flash[:notice] = "Successfully edited reservation."
        redirect_to @reservation
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

