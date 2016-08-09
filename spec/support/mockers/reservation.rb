# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')

class ReservationMock < Mocker
  def self.klass
    Reservation
  end

  def self.klass_name
    'Reservation'
  end

  private

  def for_user(user:)
    child_of_has_many(mocked_parent: user, parent_sym: :reserver,
                      child_sym: :reservations)
  end
end
