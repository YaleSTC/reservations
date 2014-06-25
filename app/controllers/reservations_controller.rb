class ReservationsController < ApplicationController

  load_and_authorize_resource
  include Autocomplete
  # this is a call to the gem method 'autocomplete' of the rails3-jquery-autocomplete gem
  # it sets up what table and attributes will be used to display autocomplete information when searched
  # via this controller.
  autocomplete :user, :last_name, extra_data: [:first_name, :login], display_value: :render_name

  layout 'application_with_sidebar'

  before_filter :require_login, only: [:index, :show]

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  public

  def index
    #define our source of reservations depending on user status
    @reservations_source = (can? :manage, Reservation) ? Reservation : current_user.reservations
    default_filter = (can? :manage, Reservation) ? :upcoming : :reserved

    filters = [:reserved, :checked_out, :overdue, :missed, :returned, :upcoming]
    #if the filter is defined in the params, store those reservations
    filters.each do |filter|
      if params[filter]
        @reservations_set = [@reservations_source.send(filter)].delete_if{|a| a.empty?}
      end
    end

    @default = false
    #if no filter is defined
    if @reservations_set.nil?
      @default = true
      @reservations_set = [@reservations_source.send(default_filter)].delete_if{|a| a.empty?}
    end
  end

  def show
    set_reservation
  end

  def new
    if cart.items.empty?
      flash[:error] = "You need to add items to your cart before making a reservation."
      redirect_to catalog_path
    else
      # error handling
      @errors = Reservation.validate_set(cart.reserver, cart.cart_reservations)

      unless @errors.empty?
        if can? :override, :reservation_errors
          flash[:error] = 'Are you sure you want to continue? Please review the errors below.'
        else
          flash[:error] = 'Please review the errors below.'
        end
      end

      # this is used to initialize each reservation later
      @reservation = Reservation.new(start_date: cart.start_date, due_date: cart.due_date, reserver_id: cart.reserver_id)
    end
  end

  def create
    #using http://stackoverflow.com/questions/7233859/ruby-on-rails-updating-multiple-models-from-the-one-controller as inspiration
    Reservation.transaction do
      begin
        # Save all the reservations at once
        cart.cart_reservations.each do |cart_res|
          @reservation = Reservation.new(params[:reservation])
          @reservation.equipment_model =  cart_res.equipment_model
          @reservation.from_admin = (can? :override, :reservation_errors)

          # save! raises RecordInvalid if validations fail,
          # RecordNotSaved if before_* callbacks fail; dealt with in rescue
          @reservation.save!
        end

        # Empty the cart
        cart.items.each { |item| CartReservation.delete(item) }
        session[:cart] = Cart.new

        # Send a reservation confirmation if so configured
        if AppConfig.first.reservation_confirmation_email_active?
          #UserMailer.reservation_confirmation(complete_reservation).deliver
        end

        # Set the flash and handle redirects
        flash[:notice] = "Reservation created successfully."
        unless can? :manage, Reservation
          redirect_to catalog_path and return
        else
          if params[:reservation][:start_date].to_date == Date::today.to_date
            flash[:notice] << " Are you simultaneously checking out equipment
            for someone? Note that only the reservation has been made. Don't
            forget to continue to checkout."
          end
          redirect_to manage_reservations_for_user_path(params[:reservation][:reserver_id]) and return
        end

      # Handle possible exceptions from the earlier save!
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        raise ActiveRecord::Rollback
        flash[:error] = "Oops, something went wrong with making your
        reservation.<br/> #{e.message}".html_safe
        redirect_to catalog_path
      end
    end
  end


  def edit
    set_reservation
    # For switching which specific EquipmentObject is reserved (see #536)
    @option_array = @reservation.equipment_model.equipment_objects.collect { |e|
		[e.name, e.id] }
  end

  def update # for editing reservations; not for checkout or check-in
    set_reservation

    # adjust dates to match intended input of Month / Day / Year
    start = Date.strptime(params[:reservation][:start_date],'%m/%d/%Y')
    due = Date.strptime(params[:reservation][:due_date],'%m/%d/%Y')

    # make sure dates are valid
    if due < start
      flash[:error] = 'Due date must be after the start date.'
      redirect_to :back and return
    end

	message = "Successfully edited reservation."

    # update attributes
    unless params[:equipment_object] == ''
		object = EquipmentObject.find(params[:equipment_object])
		unless object.available?
			r = object.current_reservation
			r.equipment_object_id = @reservation.equipment_object_id
			r.save
			message << " Note equipment item #{r.equipment_object.name} is now assigned to \
						#{ActionController::Base.helpers.link_to('reservation #' + r.id.to_s, reservation_path(r))} \
						(#{r.reserver.render_name})"
		end
		@reservation.equipment_object_id = params[:equipment_object]
	end
    @reservation.reserver_id = params[:reservation][:reserver_id]
    @reservation.start_date = start
    @reservation.due_date = due
    @reservation.notes = params[:reservation][:notes]

    # save changes to database
    @reservation.save

    # flash success and exit
    flash[:notice] = message
    redirect_to @reservation
  end

  def checkout
    error_msgs = ""
    reservations_to_be_checked_out = []
    set_user
    if !@user.terms_of_service_accepted && !params[:terms_of_service_accepted]
      flash[:error] = "You must confirm that the user accepts the Terms of Service"
      redirect_to :back and return
    elsif !@user.terms_of_service_accepted && params[:terms_of_service_accepted]
      @user.terms_of_service_accepted = true
      @user.save
    end

    # throw all the reservations that are being checked out into an array
    params[:reservations].each do |reservation_id, reservation_hash|
        if reservation_hash[:equipment_object_id] != ('' or nil) then #update attributes for all equipment that is checked off
          r = Reservation.find(reservation_id)
          r.checkout_handler = current_user
          r.checked_out = Time.now
          r.equipment_object = EquipmentObject.find(reservation_hash[:equipment_object_id])

          # deal with checkout procedures
          procedures_not_done = "" # initialize
          r.equipment_model.checkout_procedures.each do |check|
            if reservation_hash[:checkout_procedures] == nil # if none were checked, note that
              procedures_not_done += "* " + check.step + "\n"
            elsif !reservation_hash[:checkout_procedures].keys.include?(check.id.to_s) # if you didn't check it of, add to string
              procedures_not_done += "* " + check.step + "\n"
            end
          end


          # add procedures_not_done to r.notes so admin gets the errors
          # if no notes and some procedures not done
          if procedures_not_done.present?
            modified_notes = reservation_hash[:notes].present? ? reservation_hash[:notes] + "\n\n" : ""
            r.notes = modified_notes + "The following checkout procedures were not performed:\n" + procedures_not_done
            r.notes_unsent = true
          elsif reservation_hash[:notes].present? # if all procedures were done
            r.notes = reservation_hash[:notes]
            r.notes_unsent = true
          end
          r.notes.strip! if r.notes?

          # put the data into the container we defined at the beginning of this action
          reservations_to_be_checked_out << r

        end
    end

      # done with throwing things into the array
      #All-encompassing checks, only need to be done once
      if reservations_to_be_checked_out.first.nil? #Prevents the nil error from not selecting any reservations
        flash[:error] = "No reservation selected."
        redirect_to :back and return
      # move method to user model TODO
      elsif Reservation.overdue_reservations?(reservations_to_be_checked_out.first.reserver) #Checks for any overdue equipment
        error_msgs += "User has overdue equipment."
      end

      # make sure we're not checking out the same object in more than one reservation
      if !reservations_to_be_checked_out.first.checkout_object_uniqueness(reservations_to_be_checked_out) # if objects not unique, flash error
        flash[:error] = "The same equipment item cannot be simultaneously checked out in multiple reservations."
        redirect_to :back and return
      end

      # act on the errors
      if !error_msgs.empty? # If any requirements are not met...
        if can? :override, :checkout_errors # Admins can ignore them
          error_msgs = " Admin Override: Equipment has been successfully checked out even though " + error_msgs
        else # everyone else is redirected
          flash[:error] = error_msgs
          redirect_to :back and return
        end
      end

      # transaction this process ^downarrow

      # save reservations
      reservations_to_be_checked_out.each do |reservation| # updates to reservations are saved
        reservation.save! # save!
      end

      # prep for receipt page and exit
      @check_in_set = []
      @check_out_set = reservations_to_be_checked_out
      render 'receipt' and return
  rescue Exception => e
    redirect_to manage_reservations_for_user_path(reservations_to_be_checked_out.first.reserver), flash: {error: "Oops, something went wrong checking out your reservation.<br/> #{e.message}".html_safe}
  end

  def checkin
    reservations_to_be_checked_in = []

    params[:reservations].each do |reservation_id, reservation_hash|
      if reservation_hash[:checkin?] == "1" then # update attributes for all equipment that is checked off
        r = Reservation.find(reservation_id)

        if r.checked_in
          flash[:error] = "One or more items you were trying to checkout has already been checked in."
          redirect_to :back
          return
        end

        r.checkin_handler = current_user
        r.checked_in = Time.now

        # deal with checkout procedures
        procedures_not_done = "" # initialize
        r.equipment_model.checkin_procedures.each do |check|
          if reservation_hash[:checkin_procedures] == NIL # if none were checked, note that
            procedures_not_done += "* " + check.step + "\n"
          elsif !reservation_hash[:checkin_procedures].keys.include?(check.id.to_s) # if you didn"t check it of, add to string
            procedures_not_done += "* " + check.step + "\n"
          end
        end

        # add procedures_not_done to r.notes so admin gets the errors
        previous_notes = r.notes.present? ? "Checkout Notes:\n" + r.notes + "\n\n" : ""
        new_notes = reservation_hash[:notes].present? ? "Checkin Notes:\n" + reservation_hash[:notes] : ""

        if procedures_not_done.present?
          r.notes = previous_notes + new_notes + "\n\nThe following check-in procedures were not performed:\n" + procedures_not_done
          r.notes_unsent = true
        elsif new_notes.present? # if all procedures were done
          r.notes = previous_notes + new_notes # add blankline because there may well have been previous notes
          r.notes_unsent = true
        else
          r.notes = previous_notes
        end
        r.notes.strip! if r.notes?

        # put the data into the container we defined at the beginning of this action
        reservations_to_be_checked_in << r
      end
    end

    # flash errors
    if reservations_to_be_checked_in.empty?
      flash[:error] = "No reservation selected!"
      redirect_to :back and return
    end

    # save the reservations
    reservations_to_be_checked_in.each do |reservation|
      reservation.save!
    end

    # prep for receipt page and exit
    @user = reservations_to_be_checked_in.first.reserver
    @check_in_set = reservations_to_be_checked_in
    @check_out_set = []
    render 'receipt' and return
  rescue Exception => e
    redirect_to :back, flash: {error: "Oops, something went wrong checking in your reservation.<br/> #{e.message}".html_safe}
  end

  def destroy
    set_reservation
    @reservation.destroy
    flash[:notice] = "Successfully destroyed reservation."
    redirect_to reservations_url
  end

  def upcoming
    @reservations_set = [Reservation.upcoming].delete_if{|a| a.empty?}
  end

  def manage # initializer
    set_user
    @check_out_set = Reservation.due_for_checkout(@user)
    @check_in_set = Reservation.due_for_checkin(@user)
  end

  def current
    set_user
    @user_overdue_reservations_set = [Reservation.overdue_user_reservations(@user)].delete_if{|a| a.empty?}
    @user_checked_out_today_reservations_set = [Reservation.checked_out_today_user_reservations(@user)].delete_if{|a| a.empty?}
    @user_checked_out_previous_reservations_set = [Reservation.checked_out_previous_user_reservations(@user)].delete_if{|a| a.empty?}
    @user_reserved_reservations_set = [Reservation.reserved_user_reservations(@user)].delete_if{|a| a.empty?}

    render 'current_reservations'
  end

  #two paths to create receipt emails for checking in and checking out items.
  def checkout_email
    set_reservation
    if UserMailer.checkout_receipt(@reservation).deliver
      redirect_to :back
      flash[:notice] = "Successfully delivered receipt email."
    else
      redirect_to @reservation
      flash[:error] = "Unable to deliver receipt email. Please contact administrator for more support. "
    end
  end

  def checkin_email
    set_reservation
    if UserMailer.checkin_receipt(@reservation).deliver
      redirect_to :back
      flash[:notice] = "Successfully delivered receipt email."
    else
      redirect_to @reservation
      flash[:error] = "Unable to deliver receipt email. Please contact administrator for more support. "
    end
  end

  def renew
    set_reservation
    @reservation.due_date += @reservation.max_renewal_length_available.days
    if @reservation.times_renewed == NIL # this check can be removed? just run the else now?
      @reservation.times_renewed = 1
    else
      @reservation.times_renewed += 1
    end

    if !@reservation.save
      redirect_to @reservation
      flash[:error] = "Unable to update reservation dates. Please contact us for support."
    end
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js{render action: "renew_box"}
    end
  end

end
