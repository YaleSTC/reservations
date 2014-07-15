class Cart
  include ActiveModel::Validations
  include CartValidations
  validates :reserver_id, :start_date, :due_date, presence: true

  attr_accessor :items, :start_date, :due_date, :reserver_id

  def initialize
    @errors = ActiveModel::Errors.new(self)
    @items = Hash.new()
    @start_date = Date.today
    @due_date = Date.tomorrow
    @reserver_id = nil
  end

  def persisted?
    false
  end

  ## Item methods

  def get_items
    # Used in cart_validations
    # Return items where the key is the full equipment model object
    # uses 1 database call and eager loads the categories
    full_hash = Hash.new
    EquipmentModel.includes(:category).find(self.items.keys).each do |em|
      full_hash[em] = self.items[em.id]
    end
    full_hash
  end
  # Adds equipment model id to items hash
  def add_item(equipment_model)
    return if equipment_model.nil?
    key = equipment_model.id
    self.items[key] = self.items[key] ? self.items[key] + 1 : 1
  end

  # Remove equipment model id from items hash, or decrement its count
  def remove_item(equipment_model)
    return if equipment_model.nil?
    key = equipment_model.id
    self.items[key] = self.items[key] ? self.items[key] - 1 : 0
    self.items = self.items.except(key) if self.items[key] <= 0
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

  def reserve_all override=false
    # reserve all the items in the cart!
    # takes 1 argument which is whether or not
    # validations can be overriden
    reservations = prepare_all
    message = []
    reservations.each do |r|
      errors = r.validate
      if errors.empty? || override
        r.approval_status = 'auto'
        message << "Reservation for #{r.equipment_model.name} created successfully#{", even though " + errors.to_sentence[0,1].downcase + errors.to_sentence[1..-1] unless errors.empty?}.\n"
      else
        r.approval_status = 'requested'
        message << "Request for #{r.equipment_model.name} filed successfully. (#{errors.to_sentence})\n"
      end
      r.save!
    end

    purge_all

    message.join(" ")
  end

  # Returns the cart's duration
  def duration #in days
    @due_date.to_date - @start_date.to_date + 1
  end

  # Returns the reserver
  def reserver
    User.find(@reserver_id)
  end

  def fix_due_date
    if @start_date > @due_date
      @due_date = @start_date + 1.day
    end
  end
end
