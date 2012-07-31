#TODO: change set_reserver_id, set_start_date, and set_due_date to use update_all

class Cart
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validates :reserver_id, :start_date, :due_date, :presence => true

  attr_accessor :items, :start_date, :due_date, :reserver_id
  attr_reader   :errors

  def initialize
    @errors = ActiveModel::Errors.new(self)
    @items = []
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

  # Adds CartReservation to database; saves ID into items array
  def add_item(equipment_model)
    current_item = CartReservation.new(:start_date => @start_date,
      :due_date => @due_date, :reserver => self.reserver)
    current_item.equipment_model = equipment_model
    current_item.save
    @items << current_item.id
  end

  # Removes CartReservation from database and ID from items array
  def remove_item(equipment_model)
    to_be_deleted = nil
    @items.each { |item| to_be_deleted = item if CartReservation.find(item).equipment_model == equipment_model }
    CartReservation.delete(to_be_deleted)
    @items.delete(to_be_deleted)
  end

  # Returns the CartReservations that correspond to the IDs in the items array
  def cart_reservations
    cart_reservations = CartReservation.find(@items)
  end

  # Returns a hash of the equipment models in the cart with their quantities
  def models_with_quantities
    models = Hash.new
    cart_reservations.each { |res| models[res.equipment_model.id] = res.same_model_count(cart_reservations) }
    models
  end

  def empty?
    @items.empty?
  end

  ## Date methods

  # Sets start date and updates all CartReservations to match
  def set_start_date(date)
    @start_date = date
    fix_due_date
    items.each do |item|
      cart_res = CartReservation.find(item)
      cart_res.start_date = start_date
      cart_res.due_date = due_date
      cart_res.save
    end
  end

  # Sets due date and updates all CartReservations to match
  def set_due_date(date)
    @due_date = date
    fix_due_date
    items.each do |item|
      cart_res = CartReservation.find(item)
      cart_res.start_date = start_date
      cart_res.due_date = due_date
      cart_res.save
    end
  end

  # If the dates were illogical, sets due date to day after start date
  def fix_due_date
    if @start_date >= @due_date
      #TODO: allow admin to set default reservation length and respect that length here
      @due_date = @start_date + 1.day
    end
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
    @items.each do |item|
      cart_res = CartReservation.find(item)
      cart_res.reserver_id = user_id
      #cart_res.reserver = reserver
      cart_res.save
    end
  end

  # Returns the reserver
  def reserver
    reserver = User.find(@reserver_id)
  end
end
