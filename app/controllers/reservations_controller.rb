class ReservationsController < ApplicationController

  load_and_authorize_resource

  layout 'application_with_sidebar'

  before_action :require_login, only: [:index, :show]
  before_action :set_reservation, only: [:show, :edit, :update, :destroy,
     :checkout_email, :checkin_email, :renew]
  before_action :set_user, only: [:manage, :current, :checkout]

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
          if AppConfig.first.request_text.empty?
            @request_text = "Please give a short justification for this equipment request."
          else
            @request_text = AppConfig.first.request_text
          end
        end
      end

      # this is used to initialize each reservation later
      @reservation = Reservation.new(start_date: cart.start_date, due_date: cart.due_date, reserver_id: cart.reserver_id)
    end
  end

  def create
    @errors = cart.validate_all
    notes = params[:reservation][:notes]
    requested = !@errors.empty? && (cannot? :override, :reservation_errors)

    if !@errors.blank? && notes.blank?
      # there were errors but they didn't fill out the notes
      flash[:error] = "Please give a short justification for this reservation #{requested ? 'request' : 'override'}"
      @notes_required = true
      render :new and return
    end

    Reservation.transaction do
      begin

        start_date = cart.start_date
        reserver = cart.reserver_id
        unless requested
          success_message = cart.reserve_all(params[:reservation][:notes])
        else
          success_message = cart.request_all(params[:reservation][:notes])
        end

        # emails are probably failing---this code was already commented out 2014.06.19, and we don't know why.
        #if AppConfig.first.reservation_confirmation_email_active?
        #  #UserMailer.reservation_confirmation(complete_reservation).deliver
        #end

        flash[:notice] = success_message
        redirect_to catalog_path and return if (cannot? :manage, Reservation) || (requested == true)
          if start_date.to_date === Date::today.to_date
            flash[:notice] += " Are you simultaneously checking out equipment for someone? Note that\
                             only the reservation has been made. Don't forget to continue to checkout."
          end
          redirect_to manage_reservations_for_user_path(reserver) and return
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
    message = "Successfully edited reservation."
    res = reservation_params

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
    @reservation.update_attributes(res)
    if params[:new_notes]
      @reservation.notes = @reservation.notes.to_s + "\n#### New notes added at #{Time.current.to_s(:long)} by #{current_user.name}\n" + params[:new_notes]
      @reservation.save
    end


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
        r.checked_out = Time.current
        r.equipment_object_id = reservation_hash[:equipment_object_id]

        # Check that checkout procedures have been performed
        incomplete_procedures = check_procedures(r, reservation_hash, :checkout)

        # Update notes if any checkout procedures have not been performed
        r.notes = make_notes(r.notes, reservation_hash[:notes], \
                             :checkout, incomplete_procedures)

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
        flash[:notice] = 'Admin Override: Equipment has been checked out
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
      r.checked_in = Time.current

      # Check that check-in procedures have been performed
      incomplete_procedures = check_procedures(r, reservation_hash, :checkin)

      # add incomplete_procedures to r.notes so admin gets the errors
      r.notes = make_notes(r.notes, reservation_hash[:notes], \
                           :checkin, incomplete_procedures)

      # if equipment was overdue, send an email confirmation
      if r.status == 'returned overdue'
        AdminMailer.overdue_checked_in_fine_admin(r).deliver
        UserMailer.overdue_checked_in_fine(r).deliver
      end

      # put the data into the container defined at the beginning of this action
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
    @all_current_requests_by_user = @reservation.reserver.reservations.requested.reject{|res| res.id == @reservation.id}
    @errors = @reservation.validate
  end

  def approve_request
    set_reservation
    @reservation.approval_status = "approved"
    if @reservation.save
      flash[:notice] = "Request successfully approved"
      UserMailer.request_approved_notification(@reservation).deliver
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
      UserMailer.request_denied_notification(@reservation).deliver
      redirect_to reservations_path(:requested => true)
    else
      flash[:error] = "Oops! Something went wrong. Unable to deny reservation. We're not sure what that's all about."
      redirect_to @reservation
    end
  end

  def archive
    if params[:archive_note].nil? || params[:archive_note].strip.empty?
      flash[:error] = 'Reason for archiving cannot be empty.'
      redirect_to :back and return
    end
    set_reservation
    if @reservation.checked_in
      flash[:error] = 'Cannot archive checked-in reservation.'
      redirect_to :back and return
    end
    @reservation.archive(current_user, params[:archive_note]).save(validate: false)
    flash[:notice] = "Reservation successfully archived."
    redirect_to :back
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
    notes = old_notes ? old_notes + "\n\n" : ''
    procedure_kind = procedure_kind.to_s

    if new_notes || procedures.present?
      notes += "== Notes from #{procedure_kind}\n"
      notes += new_notes + "\n\n" if new_notes
    end

    if procedures.present?
      notes += "The following #{procedure_kind} procedures were not " \
      "performed:\n" + markdown_listify(procedures)
    end

    return notes.strip
  end

  def reservation_params
    params.require(:reservation)
          .permit(:checkout_handler_id, :checkin_handler_id, :approval_status,
                  :checked_out, :checked_in, :equipment_object,
                  :equipment_object_id, :notes, :notes_unsent, :times_renewed,
                  :reserver_id, :reserver, :start_date, :due_date,
                  :equipment_model_id)

  end
end
