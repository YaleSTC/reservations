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

    error_messages = []
    @reservation = Reservation.find(params[:id])
    if params[:commit] == "Check out equipment"
      iteration_number = 0
      Reservation.due_for_checkout(@reservation.reserver).to_a.each do |reservation|
        iteration_number += 1
        reservation.checkout_handler = current_user
        if Reservation.overdue_reservations?(reservation.reserver)
          error_messages << "Overdue Equipment Exists"
        end
        if Reservation.category_limit_reached?(reservation)
          error_messages << "Category Limit Reached"
        end
        if Reservation.equipment_model_limit_reached?(reservation)
          error_messages << "Equipment Limit Reached"
        end
        if Reservation.check_out_procedures_exist?(reservation)
          if params[:reservation][:checkout_procedures].nil? || (reservation.equipment_model.checkout_procedures.size != params[:reservation][:checkout_procedures].size.to_i)
            error_messages << "Checkout Procedures Not Completed"
          end
        end
        if !error_messages.empty?
          flash[:error] = error_messages.join("<br><br>")
          redirect_to :action => 'check_out' and return
        end
          reservation.checked_out = Time.now
          flash[:notice] = "Flash corresponding to iteration #{iteration_number}"
          reservation.equipment_object = EquipmentObject.find(params[:reservation][:equipment_object_id])
        if reservation.update_attributes(params[:reservation])
          flash[:notice] = "Successfully checked out iteration #{iteration_number}"
        end
      end
      redirect_to :action => 'index' and return

    elsif params[:commit] == "Check in equipment"
      Reservation.due_for_checkin(@reservation.reserver).to_a.each do |reservation|

        # handle the error case where we return an empty reservation (a checked-out reservation with no associated equipment objects)
        if Reservation.empty_reservation?(reservation)
          error_messages <<  "Empty reservation error"
        end
        if params[:reservation].nil? || params[:reservation][:equipment_object_id].nil?
          error_messages << "Confirm kit color for #{reservation.equipment_model.name}, (#{reservation.equipment_object.name})!"
        end
        if Reservation.check_in_procedures_exist?(reservation)
          if (params[:reservation][:checkin_procedures].nil? || (reservation.equipment_model.checkin_procedures.size != params[:reservation][:checkin_procedures].size.to_i))
            error_messages <<  "Checkin Procedures"
          end
        end
        if !error_messages.empty?
          flash[:error] = error_messages
          redirect_to :action => 'check_in' and return
        end
        reservation.checked_in = Time.now
        reservation.checkin_handler = current_user
        if reservation.update_attributes(params[:reservation])
          flash[:notice] = "Successfully checked in equipment."
        end
      end
      redirect_to :action => 'index' and return
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
    @check_out_set = Reservation.due_for_checkout(@reservation.reserver).to_a
  end

  def check_in
    @reservation = Reservation.find(params[:id])
    @check_in_set = Reservation.due_for_checkin(@reservation.reserver).to_a
  end


end

