# frozen_string_literal: true
class ReservationCreator
  # Service Object to create reservations in the reservations controller
  def initialize(cart:, current_user:, override: false, notes: '')
    @current_user = current_user
    @cart = cart
    @cart_errors = cart.validate_all
    @override = override
    @notes = notes
  end

  def create!
    return { result: nil, error: error } if error
    reservation_transaction
  end

  def request?
    !override && !cart_errors.blank?
  end

  private

  attr_reader :cart, :current_user, :override, :notes, :cart_errors

  def error
    return 'requests disabled' if request? && AppConfig.check(:disable_requests)
    return 'needs notes' if needs_notes?
  end

  def needs_notes?
    (request? || override?) && notes.blank?
  end

  def override?
    override && !cart_errors.blank?
  end

  def reservation_transaction
    result = {}
    Reservation.transaction do
      begin
        create_method = request? ? :request_all : :reserve_all
        cart_result = cart.send(create_method, current_user, notes)
        result = { result: cart_result, error: nil }
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
        result = { result: nil, error: e.message }
        raise ActiveRecord::Rollback
      end
    end
    result
  end
end
