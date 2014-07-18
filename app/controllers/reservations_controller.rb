class ReservationsController < ApplicationController

  load_and_authorize_resource

  layout 'application_with_sidebar'

  before_filter :require_login, only: [:index, :show]
  before_filter :set_reservation, only: [:show,:edit,:update,:destroy,:checkout_email,:checkin_email,:renew]
  def set_user
    @user = User.find(params[:user_id])
  end

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def index
    #define our source of reservations depending on user status
    @reservations_source = (can? :manage, Reservation) ? Reservation : current_user.reservations
    default_filter = (can? :manage, Reservation) ? :upcoming : :reserved

    filters = [:reserved, :checked_out, :overdue, :missed, :returned, :upcoming, :requested, :approved_requests, :denied_requests]
    #if the filter is defined in the params, store those reservations
    filters.each do |filter|
      if params[filter]
        @reservations_set = @reservations_source.send(filter)
      end
    end

    @default = false
    #if no filter is defined
    if @reservations_set.nil?
      @default = true
      @reservations_set = @reservations_source.send(default_filter)
    end
  end

  def show
  end

  def new
    if cart.items.empty?
      flash[:error] = "You need to add items to your cart before making a reservation."
      redirect_to catalog_path
    else
      # error handling
      @errors = cart.validate_all
      unless @errors.empty?
        if can? :override, :reservation_errors
          flash[:error] = 'Are you sure you want to continue? Please review the errors below.'
        else
          flash[:error] = 'Please review the errors below. If uncorrected, any reservations with errors will be filed as a request, and subject to administrator approval.'
        end
      end

      # this is used to initialize each reservation later
      @reservation = Reservation.new(start_date: cart.start_date, due_date: cart.due_date, reserver_id: cart.reserver_id)
    end
  end

  def create

    Reservation.transaction do
      begin

        start_date = cart.start_date
        if cart.validate_all.empty? || (can? :override, :reservation_errors)
          success_message = cart.reserve_all
        else
          success_message = cart.request_all
        end

        # emails are probably failing---this code was already commented out 2014.06.19, and we don't know why.
        #if AppConfig.first.reservation_confirmation_email_active?
        #  #UserMailer.reservation_confirmation(complete_reservation).deliver
        #end

        flash[:notice] = success_message
        redirect_to catalog_path and return if cannot? :manage, Reservation
          if start_date.to_date === Date::today.to_date
            flash[:notice] += " Are you simultaneously checking out equipment for someone? Note that\
                             only the reservation has been made. Don't forget to continue to checkout."
          end
          redirect_to manage_reservations_for_user_path(params[:reservation][:reserver_id]) and return
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        redirect_to catalog_path, flash: {error: "Oops, something went wrong with making your reservation.<br/> #{e.message}".html_safe}
        raise ActiveRecord::Rollback
      end
    end
  end

  def edit
    @option_array = @reservation.equipment_model.equipment_objects.collect { |e|
    [e.name, e.id] }
  end

  def update # for editing reservations; not for checkout or check-in
    #make copy of params
    res = params[:reservation].clone

    # adjust dates to match intended input of Month / Day / Year
    res[:start_date] = Date.strptime(params[:reservation][:start_date],'%m/%d/%Y')
    res[:due_date] = Date.strptime(params[:reservation][:due_date],'%m/%d/%Y')

    message = "Successfully edited reservation."
    # update attributes
    if params[:equipment_object] && params[:equipment_object] != ''
      object = EquipmentObject.find(params[:equipment_object])
      unless object.available?
        r = object.current_reservation
        r.equipment_object_id = @reservation.equipment_object_id
        r.save
        message << " Note equipment item #{r.equipment_object.name} is now assigned to \
            #{ActionController::Base.helpers.link_to('reservation #' + r.id.to_s, reservation_path(r))} \
            (#{r.reserver.render_name})"
      end
      res[:equipment_object_id] = params[:equipment_object]
    end

    # save changes to database
    Reservation.update(@reservation, res)

    # flash success and exit
    flash[:notice] = message
    redirect_to @reservation
  end

  def checkout
    error_msgs = ""
    reservations_to_be_checked_out = []
    set_user
    if !@user.terms_of_service_accepted && !params[:terms_of_service_accepted]
      flash[:error] = "You must confirm that the user accepts the Terms of Service."
      redirect_to :back and return
    elsif !@user.terms_of_service_accepted && params[:terms_of_service_accepted]
      @user.terms_of_service_accepted = true
      @user.save
    end

    # throw all the reservations that are being checked out into an array
    params[:reservations].each do |reservation_id, reservation_hash|
        if reservation_hash[:equipment_object_id] != ('' or nil) then # update attributes for all equipment that is checked off
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
      if reservations_to_be_checked_out.first.nil? # Prevents the nil error from not selecting any reservations
        flash[:error] = "No reservation selected."
        redirect_to :back and return
      # move method to user model TODO
      elsif reservations_to_be_checked_out.first.reserver.overdue_reservations?
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

        # if equipment was overdue, send an email confirmation
        if r.status == 'returned overdue'
          AdminMailer.overdue_checked_in_fine_admin(r).deliver
          UserMailer.overdue_checked_in_fine(r).deliver
        end

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
    @check_out_set = @user.due_for_checkout
    @check_in_set = @user.due_for_checkin

    render :manage, layout: 'application'
  end

  def current
    set_user
    @user_overdue_reservations_set = [Reservation.overdue.for_reserver(@user)].delete_if{|a| a.empty?}
    @user_checked_out_today_reservations_set = [Reservation.checked_out_today.for_reserver(@user)].delete_if{|a| a.empty?}
    @user_checked_out_previous_reservations_set = [Reservation.checked_out_previous.for_reserver(@user)].delete_if{|a| a.empty?}
    @user_reserved_reservations_set = [Reservation.reserved.for_reserver(@user)].delete_if{|a| a.empty?}

    render 'current_reservations'
  end

  # two paths to create receipt emails for checking in and checking out items.
  def checkout_email
    if UserMailer.checkout_receipt(@reservation).deliver
      redirect_to :back
      flash[:notice] = "Successfully delivered receipt email."
    else
      redirect_to @reservation
      flash[:error] = "Unable to deliver receipt email. Please contact administrator for more support. "
    end
  end

  def checkin_email
    if UserMailer.checkin_receipt(@reservation).deliver
      redirect_to :back
      flash[:notice] = "Successfully delivered receipt email."
    else
      redirect_to @reservation
      flash[:error] = "Unable to deliver receipt email. Please contact administrator for more support. "
    end
  end

  def renew
    message = @reservation.renew
    if message
      flash[:error] = message
      redirect_to @reservation and return
    end
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js{render action: "renew_box"}
    end
  end

  def review
    set_reservation
    @all_current_requests_by_user = @reservation.reserver.reservations.requested.delete_if{|res| res.id == @reservation.id}
    @errors = @reservation.validate
  end

  def approve_request
    set_reservation
    @reservation.approval_status = "approved"
    if @reservation.save
      flash[:notice] = "Request successfully approved"
      redirect_to reservations_path(:requested => true)
    else
      flash[:error] = "Oops! Something went wrong. Unable to approve reservation."
      redirect_to @reservation
    end
  end

  def deny_request
    set_reservation
    @reservation.approval_status = "denied"
    if @reservation.save
      flash[:notice] = "Request successfully denied"
      redirect_to reservations_path(:requested => true)
    else
      flash[:error] = "Oops! Something went wrong. Unable to deny reservation. We're not sure what that's all about."
      redirect_to @reservation
    end
  end
end
