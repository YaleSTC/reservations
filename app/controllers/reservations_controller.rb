class ReservationsController < ApplicationController

  load_and_authorize_resource

  layout 'application_with_sidebar'

  before_filter :require_login, only: [:index, :show]
  before_filter :set_reservation, only: [:show, :edit, :update, :destroy,
     :checkout_email, :checkin_email, :renew]
  before_filter :set_user, only: [:manage, :current, :checkout]

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

    filters = [:reserved, :checked_out, :overdue, :missed, :returned, :upcoming, :requested, :approved_requests, :denied_requests]
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
          flash[:error] = 'Please review the errors below. If uncorrected, your reservation will be filed as a request, and subject to administrator approval.'
        end
      end

      # this is used to initialize each reservation later
      @reservation = Reservation.new(start_date: cart.start_date, due_date: cart.due_date, reserver_id: cart.reserver_id)
    end
  end

  def create
    successful_reservations = []
    #using http://stackoverflow.com/questions/7233859/ruby-on-rails-updating-multiple-models-from-the-one-controller as inspiration
    Reservation.transaction do
      begin
        cart_reservations = cart.prepare_all
        @errors = cart.validate_all
        if @errors.empty?
          # If the reservation is a finalized reservation, save it as auto-approved ...
          params[:reservation][:approval_status] = "auto"
          success_message = "Reservation created successfully." # errors are caught in the rollback
        elsif can? :override, :reservation_errors
          # display a different flash notice for privileged persons
          params[:reservation][:approval_status] = "auto"
          success_message = "Reservation created successfully, despite the aforementioned errors."
        else
          # ... otherwise mark it as a Reservation Request.
          params[:reservation][:approval_status] = "requested"
          success_message = "This request has been successfully submitted, and is now subject to approval by an administrator."
        end

        cart_reservations.each do |cart_res|
          @reservation = Reservation.new(params[:reservation])
          @reservation.equipment_model =  cart_res.equipment_model
          @reservation.save!
          successful_reservations << @reservation
        end

        session[:cart] = Cart.new

        # emails are probably failing---this code was already commented out 2014.06.19, and we don't know why.
        #if AppConfig.first.reservation_confirmation_email_active?
        #  #UserMailer.reservation_confirmation(complete_reservation).deliver
        #end
        if can? :manage, Reservation
          if params[:reservation][:start_date].to_date === Date::today.to_date
            flash[:notice] = "Are you simultaneously checking out equipment for someone? Note that\
                             only the reservation has been made. Don't forget to continue to checkout."
          end
          redirect_to manage_reservations_for_user_path(params[:reservation][:reserver_id]) and return
        else
          flash[:notice] = success_message
          redirect_to catalog_path and return
        end
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
    unless check_tos(@user)
      redirect_to :back and return
    end

    # convert all the reservations that are being checked out into an array
    # of Reservation objects
    reservations_to_check_out = []
    params[:reservations].each do |reservation_id, reservation_hash|
      if reservation_hash[:equipment_object_id].present?
        # update attributes for all equipment that is checked off
        r = Reservation.find(reservation_id)
        r.checkout_handler = current_user
        r.checked_out = Time.now
        r.equipment_object = EquipmentObject.find(reservation_hash[:equipment_object_id])

        # Check that checkout procedures have been performed
        # check_procedures(reservation, reservation_hash, procedure_kind)
        incomplete_procedures = []
        r.equipment_model.checkout_procedures.each do |check|
          if reservation_hash[:checkout_procedures].nil? \
            || reservation_hash[:checkout_procedures].keys.exclude?(check.id.to_s)
            incomplete_procedures << check.step
          end
        end

        # Update notes if any checkout procedures have not been performed
        # make_notes(old_notes, new_notes, procedure_kind, procedures)
        reservation_hash[:notes] ||= ''
        r.notes = reservation_hash[:notes]
        if incomplete_procedures.present?
          r.notes += "\n\nThe following checkout procedures were not performed:"
          r.notes += "\n" + markdown_listify(incomplete_procedures)
          r.notes_unsent = true
        elsif reservation_hash[:notes].present? # if all procedures were done
          r.notes_unsent = true
        end
        r.notes.strip! if r.notes.present?

        # Put the data into the container defined at the start of this action
        reservations_to_check_out << r
      end
    end

    ## Basic-logic checks, only need to be done once
    # Prevent the nil error from not selecting any reservations
    if reservations_to_check_out.empty?
      flash[:error] = "No reservation selected."
      redirect_to :back and return
    end

    # Prevent checking out the same object in more than one reservation
    unless Reservation.unique_equipment_objects?(reservations_to_check_out)
      flash[:error] = "The same equipment item cannot be simultaneously checked
      out in multiple reservations."
      redirect_to :back and return
    end

    # Overdue validation
    reserver = reservations_to_check_out.first.reserver
    if reserver.overdue_reservations?
      if can? :override, :checkout_errors
        # Admins can ignore this
        error_msgs = 'Admin Override: Equipment has been checked out
        successfully, even though the reserver has overdue equipment.'
      else
        # Everyone else is redirected
        flash[:error] = 'Could not check out the equipment, because the reserver
        has reservations that are overdue.'
        redirect_to :back and return
      end
    end

    ## Save reservations
    Reservation.transaction do
      begin
        reservations_to_check_out.each do |reservation|
          reservation.save!
        end
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        flash[:error] = "Checking out your reservation failed: #{e.message}"
        redirect_to manage_reservations_for_user_path(reserver)
        raise ActiveRecord::Rollback
      end
    end

    # prep for receipt page and exit
    @check_in_set = []
    @check_out_set = reservations_to_check_out
    render 'receipt' and return
  end

  def checkin
    reservations_to_check_in = []

    params[:reservations].each do |reservation_id, reservation_hash|
      # only update attributes for all equipment that is checked off
      unless reservation_hash[:checkin?] == "1"
        next
      end

      r = Reservation.find(reservation_id)

      if r.checked_in
        flash[:error] = 'One of the items you tried to check in has already been
        checked in.'
        redirect_to :back and return
      end

      r.checkin_handler = current_user
      r.checked_in = Time.now

      # Check that check-in procedures have been performed
      # check_procedures(reservation, reservation_hash, procedure_kind)
      incomplete_procedures = []
      r.equipment_model.checkin_procedures.each do |check|
        if reservation_hash[:checkin_procedures].nil? \
          || reservation_hash[:checkin_procedures].keys.exclude?(check.id.to_s)
          incomplete_procedures << check.step
        end
      end

      # add incomplete_procedures to r.notes so admin gets the errors
      # make_notes(old_notes, new_notes, procedure_kind, procedures)
      previous_notes = r.notes.present? \
        ? "Checkout Notes:\n" + r.notes + "\n\n" \
        : ''
      new_notes = reservation_hash[:notes].present? \
        ? "Checkin Notes:\n" + reservation_hash[:notes] \
        : ''

      r.notes = previous_notes + new_notes

      if incomplete_procedures.present?
        r.notes += "\n\nThe following check-in procedures were not performed:\n"
        r.notes += markdown_listify(incomplete_procedures)
        r.notes_unsent = true
      elsif new_notes.present? # if all procedures were done
        r.notes_unsent = true
      end
      r.notes.strip! if r.notes.present?

      # if equipment was overdue, send an email confirmation
      if r.status == 'returned overdue'
        AdminMailer.overdue_checked_in_fine_admin(r).deliver
        UserMailer.overdue_checked_in_fine(r).deliver
      end

      # put the data into the container we defined at the beginning of this action
      reservations_to_check_in << r
    end

    # flash errors
    if reservations_to_check_in.empty?
      flash[:error] = "No reservation selected!"
      redirect_to :back and return
    end

    # save the reservations
    ## Save reservations
    Reservation.transaction do
      begin
        reservations_to_check_in.each do |reservation|
          reservation.save!
        end
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        flash[:error] = "Checking in your reservation failed: #{e.message}"
        redirect_to :back
        raise ActiveRecord::Rollback
      end
    end

    # prep for receipt page and exit
    @user = reservations_to_check_in.first.reserver
    @check_in_set = reservations_to_check_in
    @check_out_set = []
    render 'receipt' and return
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
    @check_out_set = @user.due_for_checkout
    @check_in_set = @user.due_for_checkin

    render :manage, layout: 'application'
  end

  def current
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

  private

  # returns a string where each item is begun with a '*'
  def markdown_listify(items)
    return '* ' + items.join("\n* ")
  end

  # Takes Reservation object, reservation_hash (item from params[:reservations])
  # and a symbol of either :checkin or :checkout as procedure_kind
  def check_procedures(reservation, reservation_hash, procedure_kind)
    r = reservation
    procedure_kind = (procedure_kind.to_s + "_procedures").to_sym
    incomplete_procedures = []
    r.equipment_model.send(procedure_kind).each do |check|
      if reservation_hash[procedure_kind].nil? \
        || reservation_hash[procedure_kind].keys.exclude?(check.id.to_s)
        incomplete_procedures << check.step
      end
    end

    return incomplete_procedures
  end

  # Takes old_notes (presumably those already existing on the reservation)
  # new_notes (from the form), procedure_kind (:checkin or :checkout) and array
  # of string steps of procedures that were not followed for procedure_kind.
  def make_notes(old_notes, new_notes, procedure_kind, procedures)
    notes = ''
    procedure_kind = procedure_kind.to_s

    if old_notes
      notes += "== Notes previous to #{procedure_kind}\n" \
      + old_notes + "\n\n"
    end

    if new_notes || procedures.present?
      notes += "== Notes from #{procedure_kind}\n"
      notes += new_notes + "\n\n" if new_notes
    end

    if procedures.present?
      notes += "The following #{procedure_kind} procedures were not"
      "performed:\n" + markdown_listify(procedures)
    end

    return notes.strip
  end
end
