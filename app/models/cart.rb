#TODO: change set_reserver_id, set_start_date, and set_due_date to use update_all

class Cart
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validates :reserver_id, :start_date, :due_date, presence: true

  attr_accessor :items, :start_date, :due_date, :reserver_id
  attr_reader   :errors

  def initialize
    @errors = ActiveModel::Errors.new(self)
    @items = {}
    @start_date = Date.today
    @due_date = Date.tomorrow
    @reserver_id = nil
  end

  def persisted?
    false
  end

  ## Functions for error handling

  def read_attribute_for_validation(attr)
    send(attr)
  end

  def Cart.human_attribute_name(attr, options = {})
    attr
  end

  def Cart.lookup_ancestors
    [self]
  end

  ## Item methods

  # Adds equipment model id to items hash
  def add_item(equipment_model)
    if items[equipment_model.id]
      items[equipment_model.id] += 1
    else
      items[equipment_model.id] = 1
    end
  end

  # Remove equipment model id from items hash, or decrement its count
  def remove_item(equipment_model)
    if items[equipment_model.id]
      items[equipment_model.id] -= 1
      if items[equipment_model.id] == 0
        items = items.except(equipment_model.id)
      end
    end
  end

  def empty?
    @items.empty?
  end

  #Create an array of all the reservations that should be renewed instead of having a new reservation
  def renewable_reservations
    user_reservations = reserver.reservations
    renewable_reservations = []
    @items.each do |item|
      cart_item_count = item.quantity #renew up to this many of the item
      matching_reservations = user_reservations.each do |res|
        # the end date should be the same as the start date
        # the reservation should be renewable
        # also the user should only renew as many reservations as they have in their cart
        if (res.due_date.to_date == @start_date &&
           res.equipment_model_id == item.equipment_model_id &&
           cart_item_count > 0 &&
           res.is_eligible_for_renew?)
          renewable_reservations << res
          cart_item_count-= 1
        end
      end
    end
    return renewable_reservations
  end


  # Returns the cart's duration
  def duration #in days
    @due_date.to_date - @start_date.to_date + 1
  end

  ## Reserver methods

  #TODO: should only have to set reserver OR reserver_id
  # Sets reserver id and updates the CartReservations to match
  def set_reserver_id(user_id)
    @reserver_id = user_id
    cart_reservations.update_all(reserver_id: @reserver_id)
  end

  # Returns the reserver
  def reserver
    reserver = User.find(@reserver_id)
  end
end
