# frozen_string_literal: true
class CheckoutHelper
  def self.checkout_reservation(r, reservations)
    check_reservation(r, reservations, 'checked out',
                      r.checkout_handler, r.checked_out)
  end

  def self.checkin_reservation(r, reservations)
    check_reservation(r, reservations, 'checked in',
                      r.checkin_handler, r.checked_in)
  end

  def self.check_reservation(r, reservations, message, handler, time)
    r.save!
    new_notes = reservations[r.id.to_s][:notes]
    r.equipment_item.make_reservation_notes(message, r,
                                            handler,
                                            new_notes, time)
  end

  def self.reservation_for(r_id, r_attrs, user)
    return if r_attrs[:equipment_item_id].blank?
    r = Reservation.includes(:reserver).find(r_id)
    # check that we don't somehow checkout a reservation that doesn't belong
    # to the @user we're checking out for (params hacking?)
    return if r.reserver != user
    r
  end

  def self.preprocess_checkout(reservations, user, checkout_handler)
    checked_out_reservations = []
    reservations.each do |r_id, r_attrs|
      r = CheckoutHelper.reservation_for(r_id, r_attrs, user)
      next if r.nil?
      checked_out_reservations << r.checkout(r_attrs[:equipment_item_id],
                                             checkout_handler,
                                             r_attrs[:checkout_procedures],
                                             r_attrs[:notes])
    end
    checked_out_reservations
  end

  def self.send_checkout_receipts(checked_out_reservations)
    checked_out_reservations.each do |res|
      UserMailer.reservation_status_update(res, 'checked out').deliver_now
    end
  end

  def self.update_tos(user)
    # update user with terms of service acceptance now that checkout worked
    return if user.terms_of_service_accepted
    user.update_attributes(terms_of_service_accepted: true)
  end

  def self.preproccess_checkins(reservations, user)
    checked_in_reservations = []
    reservations.each do |r_id, r_attrs|
      next if r_attrs[:checkin?].blank?
      r = Reservation.find(r_id)
      return nil if r.checked_in
      checked_in_reservations << r.checkin(user,
                                           r_attrs[:checkin_procedures],
                                           r_attrs[:notes])
    end
    checked_in_reservations
  end
end
