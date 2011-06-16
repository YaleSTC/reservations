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
    @reservation.checkout_handler = current_user
    if params[:commit] == "Check out equipment"
      if !@reservation.checkout_handler.is_admin
        overdue_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ? and due_date < ?", @reservation.reserver_id, Time.now.utc])
        if overdue_reservations.size >= 1
          flash.now[:error] = "This user has #{overdue_reservations.size} overdue reservation(s)! Overdue equipment must be returned before more equipment can be checked out"
          render :action => 'check_out' and return
        end
      end

      user_current_reservations = Reservation.find(:all, :conditions => ["checked_out IS NOT NULL and checked_in IS NULL and reserver_id = ?", @reservation.reserver_id])
      user_current_categories = []
      user_current_models = []
      user_current_reservations.each do |r|
        user_current_categories << r.equipment_model.category.id
        user_current_models << r.equipment_model_id
      end
      if !@reservation.checkout_handler.is_admin and (user_current_categories.count(@reservation.equipment_model.category.id) >= @reservation.equipment_model.category.max_per_user)
        flash.now[:error] = "This user already has a pending #{@reservation.equipment_model.category.name} reservation! Only #{@reservation.equipment_model.category.max_per_user} #{@reservation.equipment_model.category.name}(s) may be checked out at a time!"
      render :action => 'check_out' and return
      end
      if !@reservation.checkout_handler.is_admin and !EquipmentModel.find(@reservation.equipment_model_id).max_per_user.nil?
        if user_current_models.count(@reservation.equipment_model_id) >= @reservation.equipment_model.max_per_user
          flash.now[:error] = "This user already has a pending #{@reservation.equipment_model.name} reservation! Only #{@reservation.equipment_model.max_per_user} #{@reservation.equipment_model.name}(s) may be checked out at a time!"
        render :action => 'check_out' and return
        end
      end
      @reservation.checked_out = Time.now
    # elsif not all checkout procedures were checked
      if !@reservation.equipment_model.checkout_procedures.nil? && (params[:reservation][:checkout_procedures].nil? || (@reservation.equipment_model.checkout_procedures.size != params[:reservation][:checkout_procedures].size.to_i))
      flash.now[:error] = "Make sure to complete all checkout procedures!"
      render :action => 'check_out' and return
      else
        @reservation.equipment_object = EquipmentObject.find(params[:reservation][:equipment_object_id])
      end

    elsif params[:commit] == "Check in equipment"
      # handle the error case where we return an empty reservation (a checked-out reservation with no associated equipment objects)
      # elsif not all checkin procedures were checked
      if @reservation.equipment_object.nil?
        flash.now[:error] = "Empty reservation error"
        render :action => 'check_in' and return
      elsif params[:reservation].nil? || params[:reservation][:equipment_object_id].nil?
        flash.now[:error] = "Confirm presence of equipment!"
        render :action => 'check_in' and return
      elsif !@reservation.equipment_model.checkin_procedures.nil? && (params[:reservation][:checkin_procedures].nil? || (@reservation.equipment_model.checkin_procedures.size != params[:reservation][:checkin_procedures].size.to_i))
        flash.now[:error] = "Make sure to complete all checkin procedures!"
        render :action => 'check_in' and return
      else
        @reservation.checked_in = Time.now
        @reservation.checkin_handler = current_user
      end
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
    require_user_or_checkout_person(@reservation.reserver)
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

