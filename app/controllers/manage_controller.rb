# frozen_string_literal: true
# rubocop:disable ClassLength
class ManageController < ApplicationController
  load_and_authorize_resource
  before_action :set_user, only: [:show, :checkout]
  before_action :set_reservation, only: [:send_receipt]

  private

  def set_reservation
    @reservation = Reservation.find(params[:receipt_id])
  end

  def check_for_banned_user
    if @user.role == 'banned'
      flash[:error] = 'Banned users cannot check out equipment.'
      redirect_to(root_path) && return
    end
    true
  end

  def check_terms_of_service
    unless @user.terms_of_service_accepted ||
           params[:terms_of_service_accepted].present?
      flash[:error] = 'You must confirm that the user accepts the Terms of '\
        'Service.'
      redirect_to(:back) && return
    end
    true
  end

  def handle_overdue_reservations
    if @user.overdue_reservations?
      if can? :override, :checkout_errors
        # Admins can ignore this
        flash[:notice] = 'Admin Override: Equipment has been checked out '\
          'successfully, even though the reserver has overdue equipment.'
      else
        # Everyone else is redirected
        flash[:error] = 'Could not check out the equipment, because the '\
          'reserver has reservations that are overdue.'
        redirect_to(:back) && return
      end
    end
    true
  end

  def approve_checkout
    # check for banned user
    return unless check_for_banned_user

    # check terms of service
    return unless check_terms_of_service

    # Overdue validation
    return unless handle_overdue_reservations
    true
  end

  def check_nonemptiness_of(checked_out_reservations)
    if checked_out_reservations.empty?
      flash[:error] = 'No reservation selected.'
      redirect_to(:back) && return
    end
    true
  end

  def check_validity_of(checked_in_reservations)
    unless checked_in_reservations
      flash[:error] = 'One of the items you tried to check in has already '\
        'been checked in.'
      redirect_to(:back) && return
    end
    true
  end

  def check_uniqueness_of(checked_out_reservations)
    unless Reservation.unique_equipment_items?(checked_out_reservations)
      flash[:error] = 'The same equipment item cannot be simultaneously '\
        'checked out in multiple reservations.'
      redirect_to(:back) && return
    end
    true
  end

  def prep_receipt_page(check_in_set:, check_out_set:, user: nil)
    @check_in_set = check_in_set
    @check_out_set = check_out_set
    @user = user if user
    render('receipt', layout: 'application_with_search_sidebar') && return
  end

  public

  def show # initializer
    @check_out_set = @user.due_for_checkout.includes(:equipment_model)
    @check_in_set = @user.due_for_checkin.includes(:equipment_model)

    render :show, layout: 'application'
  end

  def checkout
    return unless approve_checkout

    checked_out_reservations =
      CheckoutHelper.preprocess_checkout(params[:reservations],
                                         @user, current_user)

    return unless check_nonemptiness_of(checked_out_reservations)
    return unless check_uniqueness_of(checked_out_reservations)

    ## Save reservations
    Reservation.transaction do
      begin
        checked_out_reservations.each do |r|
          CheckoutHelper.checkout_reservation(r, params[:reservations])
        end
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        flash[:error] = "Checking out your reservation failed: #{e.message}"
        redirect_to manage_reservations_for_user_path(@user)
        raise ActiveRecord::Rollback
      end
    end

    CheckoutHelper.update_tos(@user)
    CheckoutHelper.send_checkout_receipts(checked_out_reservations)
    prep_receipt_page(check_in_set: [], check_out_set: checked_out_reservations)
  end

  def checkin
    # see comments for checkout, this method proceeds in a similar way
    checked_in_reservations =
      CheckoutHelper.preproccess_checkins(params[:reservations], current_user)

    return unless check_validity_of(checked_in_reservations)

    return unless check_nonemptiness_of(checked_in_reservations)
    ## Save reservations
    Reservation.transaction do
      begin
        checked_in_reservations.each do |r|
          CheckoutHelper.checkin_reservation(r, params[:reservations])
        end
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        flash[:error] = "Checking in your reservation failed: #{e.message}"
        redirect_to :back
        raise ActiveRecord::Rollback
      end
    end

    prep_receipt_page(check_in_set: checked_in_reservations, check_out_set: [],
                      user: checked_in_reservations.first.reserver)
  end

  def send_receipt
    if UserMailer.reservation_status_update(@reservation, 'checked out')
                 .deliver_now
      flash[:notice] = 'Successfully delivered receipt email.'
    else
      flash[:error] = 'Unable to deliver receipt email. Please contact '\
        'administrator for more support.'
    end
    redirect_to @reservation
  end
end
