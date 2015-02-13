class Cart
  include ActiveModel::Validations
  include CartValidations
  validates :reserver_id, :start_date, :due_date, presence: true

  attr_accessor :items, :start_date, :due_date, :reserver_id

  def initialize
    @errors = ActiveModel::Errors.new(self)
    @items = {}
    @start_date = Time.zone.today
    @due_date = Time.zone.today + 1.day
    @reserver_id = nil
  end

  def persisted?
    false
  end

  ## Item methods

  def get_items # rubocop:disable AccessorMethodName
    # Used in cart_validations
    # Return items where the key is the full equipment model object
    # uses 1 database call and eager loads the categories
    full_hash = {}
    EquipmentModel
      .includes(:category, :requirements).find(items.keys).each do |em|
      full_hash[em] = items[em.id]
    end
    full_hash
  end

  # Adds equipment model id to items hash
  def add_item(equipment_model)
    return if equipment_model.nil?
    key = equipment_model.id
    items[key] = items[key] ? items[key] + 1 : 1
  end

  # Remove equipment model id from items hash, or decrement its count
  def remove_item(equipment_model)
    return if equipment_model.nil?
    key = equipment_model.id
    items[key] = items[key] ? items[key] - 1 : 0
    self.items = items.except(key) if items[key] <= 0
  end

  def empty?
    @items.empty?
  end

  # remove all items from cart
  def purge_all
    initialize
  end

  # return array of reservations crafted from the cart contents
  def prepare_all
    reservations = []
    @items.each do |id, quantity|
      quantity.times do
        reservations << Reservation.new(reserver: reserver,
                                        start_date: @start_date,
                                        due_date: @due_date,
                                        equipment_model_id: id)
      end
    end
    reservations # the start_date and due_date somehow become DateTimes...
                 # ActiveRecord magic...
  end

  def reserve_all(user, res_notes = '', request = false) # rubocop:disable all
    # reserve all the items in the cart!
    # takes 3 arguments which is the current user, whether or not
    # the equipment should be requested or reserved,
    # and what notes the reservations should be initialized with
    reservations = prepare_all
    message = []
    reservations.each do |r|
      errors = r.validate
      if request
        notes = "### Requested on #{Time.current.to_s(:long)} by "\
          "#{user.md_link}\n\n#### Notes:\n#{res_notes}"
        r.approval_status = 'requested'
        message << "Request for #{r.equipment_model.md_link} filed "\
          "successfully. #{errors.to_sentence}\n"
      else
        notes = "### Reserved on #{Time.current.to_s(:long)} by "\
          "#{user.md_link}"
        notes += "\n\n#### Notes:\n#{res_notes}" unless res_notes.nil? ||
                                                        res_notes.empty?
        r.approval_status = 'auto'
        message << "Reservation for #{r.equipment_model.md_link} created "\
          "successfully#{', even though ' + errors.to_sentence[0, 1].downcase\
          + errors.to_sentence[1..-1] unless errors.empty?}.\n"
      end
      r.notes = notes
      r.save!
      AdminMailer.request_filed(r).deliver if request
    end

    purge_all

    message.join(' ')
  end

  def request_all(user, notes = '')
    reserve_all(user, notes, true)
  end

  # Returns the cart's duration
  def duration # in days
    @due_date.to_date - @start_date.to_date + 1
  end

  # Returns the reserver
  def reserver
    User.find(@reserver_id)
  end

  def fix_due_date
    return unless @start_date > @due_date
    @due_date = @start_date + 1.day
  end

  # make sure that we don't have any non-existant models in our cart that
  # would cause errors when rendering
  def fix_items
    valid_items = EquipmentModel.where(id: items.keys).collect(&:id)
    self.items = items.select { |em, _count| valid_items.include? em }
  end
end
