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
    return if equipment_model.nil?
    if @items[equipment_model.id]
      @items[equipment_model.id] += 1
    else
      @items[equipment_model.id] = 1
    end
  end

  # Remove equipment model id from items hash, or decrement its count
  def remove_item(equipment_model)
    return if equipment_model.nil?
    if @items[equipment_model.id]
      @items[equipment_model.id] -= 1
      if @items[equipment_model.id] == 0
        @items = @items.except(equipment_model.id)
      end
    end
  end

  def empty?
    @items.empty?
  end

  # remove all items from cart
  def purge_all
    @items = Hash.new()
  end

  # return array of reservations crafted from the cart contents
  def prepare_all
    reservations = []
    @items.each do |id, quantity|
      quantity.times do
        reservations << Reservation.new(reserver: self.reserver,
                                        start_date: @start_date,
                                        due_date: @due_date,
                                        equipment_model_id: id)
      end
    end
    reservations
  end

  # Returns the cart's duration
  def duration #in days
    @due_date.to_date - @start_date.to_date + 1
  end

  # Returns the reserver
  def reserver
    User.find(@reserver_id)
  end
end
