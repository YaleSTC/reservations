class Cart
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validates :start_date, :due_date, :presence => true

  attr_accessor :items, :start_date, :due_date, :reserver_id
  attr_reader   :errors

  def initialize
    @errors = ActiveModel::Errors.new(self)
    @items = []
    @start_date = Date.today
    @due_date = Date.today
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
    cart_reservations = []
    @items.each { |item| cart_reservations << CartReservation.find(item) }
    cart_reservations
  end

  # Returns a hash of the equipment models in the cart with their quantities
  def models_with_quantities
    mods = Hash.new
    cart_reservations.each { |res| mods[res.equipment_model.id] = res.count(cart_reservations) }
    mods
  end

  #TODO: is this necessary?
  def empty?
    @items.empty?
  end

  ## Date methods

  # Sets start date and updates all CartReservations to match
  def set_start_date(date)
    @start_date = date
    fix_due_date
    items.each do |item|
      cartres = CartReservation.find(item)
      cartres.start_date = start_date
      cartres.due_date = due_date
      cartres.save
    end
  end

  # Sets due date and updates all CartReservations to match
  def set_due_date(date)
    @due_date = date
    fix_due_date
    items.each do |item|
      cartres = CartReservation.find(item)
      cartres.start_date = start_date
      cartres.due_date = due_date
      cartres.save
    end
  end

  # If the dates were illogical, sets due date to day after start date
  def fix_due_date
    if @start_date >= @due_date
      #TODO: allow admin to set default reservation length and respect that length here
      @due_date = @start_date + 1.day
    end
  end

  # Returns the cart's duration
  def duration #in days
    @due_date - @start_date + 1
  end

  ## Reserver methods

  # Sets reserver id and updates the CartReservations to match
  def set_reserver_id(user_id)
    @reserver_id = user_id
    @items.each do |item|
      cartres = CartReservation.find(item)
      cartres.reserver_id = user_id
      cartres.reserver = reserver
      cartres.save
    end
  end

  # Returns the reserver
  def reserver
    reserver = User.find(@reserver_id)
  end
end
