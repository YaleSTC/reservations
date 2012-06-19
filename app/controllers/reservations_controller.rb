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
      @reservations_set = [current_user.reservations.overdue, current_user.reservations.checked_out, current_user.reservations.pending ].delete_if{|a| a.empty?}
    end
  end

  def show
    @reservation = Reservation.find(params[:id])
  end

  def show_all #Action called in _reservations_list partial view, allows checkout person to view all current reservations for one user
    @user = User.find(params[:user_id])
    @user_reservations_set = Reservation.active_user_reservations(@user)
  end

  def new
    if cart.items.empty?
      flash[:error] = "You need to add items to your cart before making a reservation."
      redirect_to catalog_path
    else
      #this is used to initialize each reservation later
      @reservation = Reservation.new(start_date: cart.start_date, due_date: cart.due_date)
    end
  end

# old method that does not split reservations by item, needs to be deleted by end of summer 12
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
    #using http://stackoverflow.com/questions/7233859/ruby-on-rails-updating-multiple-models-from-the-one-controller as inspiration
    respond_to do |format|
      Reservation.transaction do
        begin
          cart.items.each do |item|
            emodel = item.equipment_model
            item.quantity.times do |q|    # accounts for reserving multiple equipment objects of the same equipment model (mainly for admins)
              @reservation = Reservation.new(params[:reservation])
              @reservation.equipment_model =  emodel
            end
          end
          UserMailer.reservation_confirmation(@reservation).deliver
          session[:cart] = Cart.new
          format.html {redirect_to catalog_path, :flash => {:notice => "Reservation created" } }
        rescue
          format.html {redirect_to catalog_path, :flash => {:error => "Oops, something went wrong with making your reservation"} }
          raise ActiveRecord::Rollback
        end
      end
    end
  end


  def edit
    @reservation = Reservation.find(params[:id])
  end

  def update

    error_msgs = ""
    if params[:commit] == "Check out equipment"

      reservations_to_be_checked_out = []
      reservation_check_out_procedures_count = []
      params[:reservations].each do |reservation_id, reservation_hash|
        if reservation_hash[:checkout?] == "1" then #update attributes for all equipment that is checked off
          r = Reservation.find(reservation_id)
          r.checkout_handler = current_user
          r.checked_out = Time.now
          r.equipment_object = EquipmentObject.find(reservation_hash[:equipment_object_id])
          reservations_to_be_checked_out << r
          reservation_check_out_procedures_count << (reservation_hash[:checkout_procedures] || []).count #There is no editable "checkout procedures count" attribute for reservations. For now, I have these two arrays, and compare them in a hash to make sure that all checkout procedures are checked off
        end
      end

      #All-encompassing checks, only need to be done once
      if reservations_to_be_checked_out.first.nil? #Prevents the nil error from not selecting any reservations
        flash[:error] = "No reservation selected!"
        redirect_to :back and return
      elsif Reservation.overdue_reservations?(reservations_to_be_checked_out.first.reserver) #Checks for any overdue equipment
        error_msgs += "User has overdue equipment."
      end

      #Checks that must be iterated over each individual reservation
      error_msgs += reservations_to_be_checked_out.first.check_out_permissions(reservations_to_be_checked_out, reservation_check_out_procedures_count) #This method checks the Category Max Per User, Equipment Model Max per User, and whether all the checkout procedures have been checked off
      if !error_msgs.empty? #If any requirements are not met...
        if current_user.is_admin_in_adminmode? #Admins can ignore them
          error_msgs = " Admin Override: Equipment has been successfully checked out even though " + error_msgs
        else #everyone else is redirected
          flash[:error] = error_msgs
          redirect_to :back and return
        end
      end
      reservations_to_be_checked_out.each do |reservation| #updates to reservations are saved
        reservation.save
      end
      flash[:notice] = error_msgs.empty? ? "Successfully checked out equipment!" : error_msgs #Allows admins to see all errors, but still checkout successfully
      redirect_to :action => 'show' and return

    elsif params[:commit] == "Check in equipment"

      if params[:reservations].nil? #Prevents the nil error from not selecting any reservations
        flash[:error] = "No reservation selected!"
        redirect_to :back and return
      end

      reservations_to_be_checked_in = []
      reservation_check_in_procedures_count = []
      params[:reservations].each do |reservation_id, reservation_hash|
        if reservation_hash[:checkin?] == "1"  then
          r = Reservation.find(reservation_id)
          r.checkin_handler = current_user
          r.checked_in = Time.now
          reservations_to_be_checked_in << r
          reservation_check_in_procedures_count << (reservation_hash[:checkin_procedures] || []).count #Like above, accounting for check in procedures count using two arrays
        else
          flash[:error] = "You filled out check in procedures without selecting the reservation!" #Prevents the nil error from selecting checkout procedures, but no reservations.
          redirect_to :back and return
        end
      end

      error_msgs = reservations_to_be_checked_in.first.check_in_permissions(reservations_to_be_checked_in, reservation_check_in_procedures_count) #This method currently just counts the check in procedures to make sure they are all checked off
      if !error_msgs.empty?
        flash[:error] = error_msgs
        redirect_to :back and return
      else
        reservations_to_be_checked_in.each do |reservation|
          reservation.save
        end
        flash[:notice] = "Successfully checked in equipment!"
        redirect_to :action => 'show' and return
      end

    elsif params[:commit] == "Submit" #For editing reservations
      @reservation = Reservation.find(params[:id])
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
    @user = User.find(params[:user_id])
    @check_out_set = Reservation.due_for_checkout(@user)
  end

  def check_out_single
    @reservation = Reservation.find(params[:id])
  end

  def check_in
    @user =  User.find(params[:user_id])
    @check_in_set = Reservation.due_for_checkin(@user)
  end

  def check_in_single
    @reservation =  Reservation.find(params[:id])
  end

  def checkout_email
    @reservation =  Reservation.find(params[:id])
    if UserMailer.checkout_receipt(@reservation).deliver
      redirect_to :back
      flash[:notice] = "Delivered receipt email."
    else 
      redirect_to @reservation
      flash[:error] = "Unable to deliver receipt email. Please contact administrator for more support. "
    end
  end
  
  def checkin_email
    @reservation =  Reservation.find(params[:id])
    if UserMailer.checkin_receipt(@reservation).deliver
      redirect_to :back
      flash[:notice] = "Delivered receipt email."
    else 
      redirect_to @reservation
      flash[:error] = "Unable to deliver receipt email. Please contact administrator for more support. "
    end
  end
  autocomplete :user, [:last_name, :first_name, :login], :extra_data => [:first_name, :login], :display_value => :render_name
end

