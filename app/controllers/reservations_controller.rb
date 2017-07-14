# frozen_string_literal: true
# rubocop:disable ClassLength
class ReservationsController < ApplicationController
  load_and_authorize_resource

  before_action :set_user, only: [:current, :checkout]

  private

  def reservation
    @reservation ||= Reservation.find(params[:id])
  end

  def set_index_dates
    session[:index_start_date] ||= Time.zone.today - 7.days
    session[:index_end_date] ||= Time.zone.today + 7.days
    @start_date = session[:index_start_date]
    @end_date = session[:index_end_date]
  end

  def set_filter
    # set the filter for #index action, pulling from session, then
    # params, then falling back to default

    f = (can? :manage, Reservation) ? :upcoming : :reserved

    @filters = [:reserved, :checked_out, :overdue, :returned, :returned_overdue,
                :upcoming, :requested, :approved_requests, :denied, :archived]
    @filters << :missed unless AppConfig.check :res_exp_time

    # if filter in session set it
    if session[:filter]
      f = session[:filter]
      session[:filter] = nil
    else
      # if the filter is defined in the params, store those reservations
      @filters.each do |filter|
        next unless params[filter]
        f = filter
        break
      end
    end
    f
  end

  def set_counts(source, with_time)
    @all_counts = {}
    @time_counts = {}
    @filters.each do |f|
      @all_counts[f] = source.send(f).count
      @time_counts[f] = with_time.send(f).count
    end
  end

  public

  def index
    set_index_dates
    @filter = set_filter
    @view_all = session[:all_dates]

    source = if can? :manage, Reservation
               Reservation
             else
               current_user.reservations
             end

    time = if session[:all_dates]
             source
           else
             source.starts_on_days(@start_date, @end_date)
           end

    set_counts(source, time)
    @reservations_set = time.send(@filter)
  end

  def update_index_dates
    session[:all_dates] = false
    session[:index_start_date] = params[:list][:start_date].to_date
    session[:index_end_date] = params[:list][:end_date].to_date
    session[:filter] = params[:list][:filter].to_sym
    redirect_to action: 'index'
  end

  def view_all_dates
    session[:all_dates] = true
    redirect_to action: 'index'
  end

  def show
  end

  def new # rubocop:disable MethodLength
    if cart.items.empty?
      flash[:error] = 'You need to add items to your cart before making a '\
        'reservation.'
      redirect_loc = (request.env['HTTP_REFERER'].present? ? :back : root_path)
      redirect_to redirect_loc
    else
      # error handling
      @errors = cart.validate_all
      unless @errors.empty?
        if can? :override, :reservation_errors
          flash[:error] = 'Are you sure you want to continue? Please review '\
            'the errors below.'
        else
          flash[:error] = 'Please review the errors below. If uncorrected, '\
            'any reservations with errors will be filed as a request, and '\
            'subject to administrator approval.'
        end
      end

      # this is used to initialize each reservation later
      @reservation = Reservation.new(start_date: cart.start_date,
                                     due_date: cart.due_date,
                                     reserver_id: cart.reserver_id)
    end
  end

  def create # rubocop:disable all
    @errors = cart.validate_all
    notes = params[:reservation][:notes]
    requested = !@errors.empty? && (cannot? :override, :reservation_errors)

    # check for missing notes and validation errors
    if !@errors.blank? && notes.blank?
      # there were errors but they didn't fill out the notes
      flash[:error] = 'Please give a short justification for this '\
        "reservation #{requested ? 'request' : 'override'}"
      @notes_required = true
      if AppConfig.get(:request_text).empty?
        @request_text = 'Please give a short justification for this '\
          'equipment request.'
      else
        @request_text = AppConfig.get(:request_text)
      end
      render(:new) && return
    end

    Reservation.transaction do
      begin
        start_date = cart.start_date
        reserver = cart.reserver_id
        notes = format_errors(@errors) + notes.to_s
        if requested
          flash[:notice] = cart.request_all(current_user,
                                            params[:reservation][:notes])
        else
          flash[:notice] = cart.reserve_all(current_user,
                                            params[:reservation][:notes])
        end

        if (cannot? :manage, Reservation) || (requested == true)
          redirect_to(catalog_path) && return
        end
        if start_date == Time.zone.today
          flash[:notice] += ' Are you simultaneously checking out equipment '\
            'for someone? Note that only the reservation has been made. '\
            'Don\'t forget to continue to checkout.'
        end
        redirect_to(manage_reservations_for_user_path(reserver)) && return
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        redirect_to catalog_path, flash: { error: 'Oops, something went '\
          "wrong with making your reservation.<br/> #{e.message}".html_safe }
        raise ActiveRecord::Rollback
      end
    end
  end

  def edit
    @option_array =
      reservation.equipment_model.equipment_items
                 .collect { |e| [e.name, e.id] }
  end

  # for editing reservations; not for checkout or check-in
  def update # rubocop:disable all
    @reservation = Reservation.find(params[:id])
    message = 'Successfully edited reservation.'
    res = reservation_params
    # add new equipment item id to hash if it's being changed and save old
    # and new items for later
    unless params[:equipment_item].blank?
      res[:equipment_item_id] = params[:equipment_item]
      new_item = EquipmentItem.find(params[:equipment_item])
      old_item =
        EquipmentItem.find_by id: reservation.equipment_item_id
      # check to see if new item is available
      unless new_item.available?
        r = new_item.current_reservation
        r.update(current_user,
                 { equipment_item_id: reservation.equipment_item_id },
                 '')
      end
    end

    # save changes to database
    reservation.update(current_user, res, params[:new_notes])
    if reservation.save
      # code for switching equipment items
      unless params[:equipment_item].blank?
        # if the item was previously assigned to a different reservation
        if r
          r.save
          # clean up this code with a model method?
          message << " Note equipment item #{r.equipment_item.md_link} is "\
            " now assigned to #{r.md_link} (#{r.reserver.md_link})"
        end

        # update the item history / histories
        old_item&.make_switch_notes(reservation, r, current_user)

        new_item.make_switch_notes(r, reservation, current_user)
      end

      # flash success and exit
      flash[:notice] = message
      redirect_to reservation
    else
      flash[:error] = "Unable to update reservation:\n"\
        "#{reservation.errors.full_messages.to_sentence}"
      redirect_to edit_reservation_path(reservation)
    end
  end

  def destroy
    reservation.destroy
    flash[:notice] = 'Successfully destroyed reservation.'
    redirect_to reservations_url
  end

  def upcoming
    @reservations_set = [Reservation.upcoming].delete_if(&:empty?)
  end

  def current
    if params[:banned] && current_user.view_mode != 'superuser'
      redirect_to(root_path) && return
    end
    @user_overdue_reservations_set =
      [Reservation.overdue.for_reserver(@user)].delete_if(&:empty?)
    @user_checked_out_today_reservations_set =
      [Reservation.checked_out_today.for_reserver(@user)].delete_if(&:empty?)
    @user_checked_out_previous_reservations_set =
      [Reservation.checked_out_previous.for_reserver(@user)]
      .delete_if(&:empty?)
    @user_reserved_reservations_set =
      [Reservation.reserved.for_reserver(@user)].delete_if(&:empty?)

    render 'current_reservations'
  end

  def renew
    message = reservation.renew(current_user)
    if message
      flash[:error] = message
      redirect_to(reservation) && return
    else
      flash[:notice] = 'Your reservation has been renewed until '\
        "#{reservation.due_date.to_s(:long)}."
      redirect_to reservation
    end
  end

  def review
    @all_current_requests_by_user =
      reservation.reserver.reservations.requested.reject do |res|
        res.id == reservation.id
      end
    @errors = reservation.validate
  end

  def approve_request
    reservation.status = 'reserved'
    reservation.notes = @reservation.notes.to_s # in case of nil
    reservation.notes += "\n\n### Approved on #{Time.zone.now.to_s(:long)} "\
      "by #{current_user.md_link}"
    if reservation.save
      flash[:notice] = 'Request successfully approved'
      UserMailer.reservation_status_update(reservation,
                                           'request approved').deliver_now
      redirect_to reservations_path(requested: true)
    else
      flash[:error] = 'Oops! Something went wrong. Unable to approve '\
        'reservation.'
      redirect_to reservation
    end
  end

  def deny_request
    reservation.status = 'denied'
    reservation.notes = reservation.notes.to_s # in case of nil
    reservation.notes += "\n\n### Denied on #{Time.zone.now.to_s(:long)} by "\
      "#{current_user.md_link}"
    if reservation.save
      flash[:notice] = 'Request successfully denied'
      UserMailer.reservation_status_update(reservation).deliver_now
      redirect_to reservations_path(requested: true)
    else
      flash[:error] = 'Oops! Something went wrong. Unable to deny '\
        'reservation. We\'re not sure what that\'s all about.'
      redirect_to reservation
    end
  end

  def archive # rubocop:disable all
    if params[:archive_cancelled]
      flash[:notice] = 'Reservation archiving cancelled.'
      redirect_to(:back) && return
    elsif params[:archive_note].nil? || params[:archive_note].strip.empty?
      flash[:error] = 'Reason for archiving cannot be empty.'
      redirect_to(:back) && return
    end
    if reservation.checked_in
      flash[:error] = 'Cannot archive checked-in reservation.'
      redirect_to(:back) && return
    end

    begin
      reservation.archive(current_user, params[:archive_note])
                 .save(validate: false)
      # archive equipment item if checked out
      if reservation.equipment_item
        reservation.equipment_item
                   .make_reservation_notes('archived',
                                           reservation, current_user,
                                           params[:archive_note],
                                           reservation.checked_in)
        if AppConfig.check(:autodeactivate_on_archive)
          reservation.equipment_item.deactivate(user: current_user,
                                                reason: params[:archive_note])
          flash_end = ' The equipment item has been automatically deactivated.'
        end
      end
      flash[:notice] = "Reservation successfully archived.#{flash_end}"
    rescue ActiveRecord::RecordNotSaved => e
      flash[:error] = "Archiving your reservation failed: #{e.message}"
    end
    redirect_to :back
  end

  private

  def reservation_params
    params.require(:reservation)
          .permit(:checkout_handler_id, :checkin_handler_id,
                  :checked_out, :checked_in, :equipment_item, :due_date,
                  :equipment_item_id, :notes, :notes_unsent, :times_renewed,
                  :reserver_id, :reserver, :start_date, :equipment_model_id)
  end

  def format_errors(errors)
    return '' if errors.blank?
    "*Validations violated:* #{errors.to_sentence}\n*Justification: *"
  end
end
