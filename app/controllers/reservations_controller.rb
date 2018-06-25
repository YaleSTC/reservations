# frozen_string_literal: true

# rubocop:disable ClassLength
class ReservationsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  load_and_authorize_resource

  before_action :set_reservation,
                only: %i[show edit update destroy checkout_email
                         checkin_email renew review approve_request
                         deny_request]
  before_action :set_user, only: %i[manage current checkout]

  private

  def set_user
    @user = User.find(params[:user_id])
    return unless @user.role == 'banned'
    flash[:error] = 'This user is banned and cannot check out equipment.'
    params[:banned] = true
  end

  def set_reservation
    @reservation = Reservation.find(params[:id])
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

    f = can?(:manage, Reservation) ? :upcoming : :reserved

    @filters = %i[reserved checked_out overdue returned returned_overdue
                  upcoming requested approved_requests denied archived]
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

  def show; end

  def new
    if cart.items.empty?
      flash[:error] = 'You need to add items to your cart before making a '\
        'reservation.'
      redirect_back(fallback_location: root_path) && return
    end
    @errors = cart.validate_all
    unless @errors.empty?
      flash[:error] = if can? :override, :reservation_errors
                        'Are you sure you want to continue? Please review '\
                          'the errors below.'
                      else
                        'Please review the errors below. If uncorrected, '\
                          'any reservations with errors will be filed as a '\
                          'request, and subject to administrator approval.'
                      end
    end

    # this is used to initialize each reservation later
    @reservation = Reservation.new(start_date: cart.start_date,
                                   due_date: cart.due_date,
                                   reserver_id: cart.reserver_id)
  end

  def create # rubocop:disable all
    @errors = cart.validate_all
    notes = params[:reservation][:notes]
    requested = !@errors.empty? && (cannot? :override, :reservation_errors)

    # check for missing notes and validation errors
    if @errors.present? && notes.blank?
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
        msg = 'Oops, something went wrong with making your '\
                "reservation.<br/> #{sanitize e.message}"
        redirect_to catalog_path, flash: { error: msg }
        raise ActiveRecord::Rollback
      end
    end
  end

  def edit
    @option_array =
      @reservation.equipment_model.equipment_items
                  .collect { |e| [e.name, e.id] }
  end

  # for editing reservations; not for checkout or check-in
  def update # rubocop:disable all
    message = 'Successfully edited reservation.'
    res = reservation_params
    # add new equipment item id to hash if it's being changed and save old
    # and new items for later
    if params[:equipment_item].present?
      res[:equipment_item_id] = params[:equipment_item]
      new_item = EquipmentItem.find(params[:equipment_item])
      old_item =
        EquipmentItem.find_by id: @reservation.equipment_item_id
      # check to see if new item is available
      unless new_item.available?
        r = new_item.current_reservation
        r.update(current_user,
                 { equipment_item_id: @reservation.equipment_item_id },
                 '')
      end
    end

    # save changes to database
    @reservation.update(current_user, res, params[:new_notes])
    if @reservation.save
      # code for switching equipment items
      if params[:equipment_item].present?
        # if the item was previously assigned to a different reservation
        if r
          r.save
          # clean up this code with a model method?
          message << " Note equipment item #{r.equipment_item.md_link} is "\
            " now assigned to #{r.md_link} (#{r.reserver.md_link})"
        end

        # update the item history / histories
        old_item&.make_switch_notes(@reservation, r, current_user)

        new_item.make_switch_notes(r, @reservation, current_user)
      end

      # flash success and exit
      flash[:notice] = message
      redirect_to @reservation
    else
      flash[:error] = "Unable to update reservation:\n"\
        "#{@reservation.errors.full_messages.to_sentence}"
      redirect_to edit_reservation_path(@reservation)
    end
  end

  def checkout # rubocop:disable all
    # convert all the reservations that are being checked out into an array
    # of Reservation objects. only select the ones who are selected, eg
    # they have an equipment item id set.

    ## Basic-logic checks, only need to be done once

    # check for banned user
    if @user.role == 'banned'
      flash[:error] = 'Banned users cannot check out equipment.'
      redirect_to(root_path) && return
    end

    # check terms of service
    unless @user.terms_of_service_accepted ||
           params[:terms_of_service_accepted].present?
      flash[:error] = 'You must confirm that the user accepts the Terms of '\
        'Service.'
      redirect_back(fallback_location: root_path) && return
    end

    # Overdue validation
    if @user.overdue_reservations?
      if can? :override, :checkout_errors
        # Admins can ignore this
        flash[:notice] = 'Admin Override: Equipment has been checked out '\
          'successfully, even though the reserver has overdue equipment.'
      else
        # Everyone else is redirected
        flash[:error] = 'Could not check out the equipment, because the '\
          'reserver has reservations that are overdue.'
        redirect_back(fallback_location: root_path) && return
      end
    end

    unless params[:reservations]
      flash[:notice] = 'No reservations selected for checkout.'
      redirect_back(fallback_location: root_path) && return
    end

    checked_out_reservations = []
    params[:reservations].each do |r_id, r_attrs|
      next if r_attrs[:equipment_item_id].blank?
      r = Reservation.includes(:reserver).find(r_id)
      # check that we don't somehow checkout a reservation that doesn't belong
      # to the @user we're checking out for (params hacking?)
      next if r.reserver != @user
      checked_out_reservations <<
        r.checkout(r_attrs[:equipment_item_id], current_user,
                   r_attrs[:checkout_procedures], r_attrs[:notes])
    end

    if checked_out_reservations.empty?
      flash[:error] = 'No reservation selected.'
      redirect_back(fallback_location: root_path) && return
    end

    unless Reservation.unique_equipment_items?(checked_out_reservations)
      flash[:error] = 'The same equipment item cannot be simultaneously '\
        'checked out in multiple reservations.'
      redirect_back(fallback_location: root_path) && return
    end

    ## Save reservations
    Reservation.transaction do
      begin
        checked_out_reservations.each do |r|
          r.save!
          # update equipment item notes
          new_notes = params[:reservations][r.id.to_s][:notes]
          r.equipment_item.make_reservation_notes('checked out', r,
                                                  r.checkout_handler,
                                                  new_notes, r.checked_out)
        end
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        flash[:error] = "Checking out your reservation failed: #{e.message}"
        redirect_to manage_reservations_for_user_path(@user)
        raise ActiveRecord::Rollback
      end
    end

    # update user with terms of service acceptance now that checkout worked
    unless @user.terms_of_service_accepted
      @user.update_attributes(terms_of_service_accepted: true)
    end

    # Send checkout receipts
    checked_out_reservations.each do |res|
      UserMailer.reservation_status_update(res, 'checked out').deliver_now
    end

    # prep for receipt page and exit
    @check_in_set = []
    @check_out_set = checked_out_reservations
    render('receipt', layout: 'application_with_search_sidebar') && return
  end

  def checkin # rubocop:disable all
    # see comments for checkout, this method proceeds in a similar way

    unless params[:reservations]
      flash[:notice] = 'No reservations selected for check in.'
      redirect_back(fallback_location: root_path) && return
    end

    checked_in_reservations = []
    params[:reservations].each do |r_id, r_attrs|
      next if r_attrs[:checkin?].blank?
      r = Reservation.find(r_id)
      if r.checked_in
        flash[:error] = 'One of the items you tried to check in has already '\
          'been checked in.'
        # rubocop:disable Lint/NonLocalExitFromIterator
        redirect_back(fallback_location: root_path) && return
        # rubocop:enable Lint/NonLocalExitFromIterator
      end

      checked_in_reservations << r.checkin(current_user,
                                           r_attrs[:checkin_procedures],
                                           r_attrs[:notes])
    end

    if checked_in_reservations.empty?
      flash[:error] = 'No reservation selected!'
      redirect_back(fallback_location: root_path) && return
    end

    ## Save reservations
    Reservation.transaction do
      begin
        checked_in_reservations.each do |r|
          r.save!
          # update equipment item notes
          new_notes = params[:reservations][r.id.to_s][:notes]
          r.equipment_item.make_reservation_notes('checked in', r,
                                                  r.checkin_handler, new_notes,
                                                  r.checked_in)
        end
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        flash[:error] = "Checking in your reservation failed: #{e.message}"
        redirect_back(fallback_location: root_path)
        raise ActiveRecord::Rollback
      end
    end

    # prep for receipt page and exit
    @user = checked_in_reservations.first.reserver
    @check_in_set = checked_in_reservations
    @check_out_set = []
    render('receipt', layout: 'application_with_search_sidebar') && return
  end

  def destroy
    @reservation.destroy
    flash[:notice] = 'Successfully destroyed reservation.'
    redirect_to reservations_url
  end

  def upcoming
    @reservations_set = [Reservation.upcoming].delete_if(&:empty?)
  end

  def manage # initializer
    @check_out_set = @user.due_for_checkout
                          .includes(equipment_model: :checkout_procedures)
    @check_in_set = @user.due_for_checkin
                         .includes(equipment_model: :checkin_procedures)

    render :manage, layout: 'application'
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

  def send_receipt
    status = if @reservation.checked_in.present?
               'returned'
             elsif @reservation.checked_out.present?
               'checked out'
             else
               ''
             end
    if UserMailer.reservation_status_update(@reservation, status).deliver_now
      flash[:notice] = 'Successfully delivered receipt email.'
    else
      flash[:error] = 'Unable to deliver receipt email. Please contact '\
        'administrator for more support.'
    end
    redirect_to @reservation
  end

  def renew
    message = @reservation.renew(current_user)
    if message
      flash[:error] = message
      redirect_to(@reservation) && return
    else
      flash[:notice] = 'Your reservation has been renewed until '\
        "#{@reservation.due_date.to_s(:long)}."
      redirect_to @reservation
    end
  end

  def review
    @reserver = @reservation.reserver
    @all_current_requests_by_user =
      @reserver.reservations.requested.reject do |res|
        res.id == @reservation.id
      end
    @errors = @reservation.validate
  end

  def approve_request
    @reservation.status = 'reserved'
    @reservation.notes = @reservation.notes.to_s # in case of nil
    @reservation.notes += "\n\n### Approved on #{Time.zone.now.to_s(:long)} "\
      "by #{current_user.md_link}"
    if @reservation.save
      flash[:notice] = 'Request successfully approved'
      UserMailer.reservation_status_update(@reservation,
                                           'request approved').deliver_now
      redirect_to reservations_path(requested: true)
    else
      flash[:error] = 'Oops! Something went wrong. Unable to approve '\
        'reservation.'
      redirect_to @reservation
    end
  end

  def deny_request
    @reservation.status = 'denied'
    @reservation.notes = @reservation.notes.to_s # in case of nil
    @reservation.notes += "\n\n### Denied on #{Time.zone.now.to_s(:long)} by "\
      "#{current_user.md_link}"
    if @reservation.save
      flash[:notice] = 'Request successfully denied'
      UserMailer.reservation_status_update(@reservation).deliver_now
      redirect_to reservations_path(requested: true)
    else
      flash[:error] = 'Oops! Something went wrong. Unable to deny '\
        'reservation. We\'re not sure what that\'s all about.'
      redirect_to @reservation
    end
  end

  def archive # rubocop:disable all
    if params[:archive_cancelled]
      flash[:notice] = 'Reservation archiving cancelled.'
      redirect_back(fallback_location: root_path) && return
    elsif params[:archive_note].nil? || params[:archive_note].strip.empty?
      flash[:error] = 'Reason for archiving cannot be empty.'
      redirect_back(fallback_location: root_path) && return
    end
    set_reservation
    if @reservation.checked_in
      flash[:error] = 'Cannot archive checked-in reservation.'
      redirect_back(fallback_location: root_path) && return
    end

    begin
      @reservation.archive(current_user, params[:archive_note])
                  .save(validate: false)
      # archive equipment item if checked out
      if @reservation.equipment_item
        @reservation.equipment_item
                    .make_reservation_notes('archived',
                                            @reservation, current_user,
                                            params[:archive_note],
                                            @reservation.checked_in)
        if AppConfig.check(:autodeactivate_on_archive)
          @reservation.equipment_item.deactivate(user: current_user,
                                                 reason: params[:archive_note])
          flash_end = ' The equipment item has been automatically deactivated.'
        end
      end
      flash[:notice] = "Reservation successfully archived.#{flash_end}"
    rescue ActiveRecord::RecordNotSaved => e
      flash[:error] = "Archiving your reservation failed: #{e.message}"
    end
    redirect_back(fallback_location: root_path)
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
