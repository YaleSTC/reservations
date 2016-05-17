class Cart # rubocop:disable ClassLength
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
    # uses 1 database call and eager loads the requirements
    full_hash = {}
    EquipmentModel
      .includes(:requirements).find(items.keys).each do |em|
      full_hash[em] = items[em.id]
    end
    full_hash
  end

  def get_categories # rubocop:disable AccessorMethodName
    cat_hash = {}
    ems = EquipmentModel.where(id: items.keys).includes(:category)
    items.each_with_index do |(_em_id, q), index|
      cat_hash[ems[index].category] ||= 0
      cat_hash[ems[index].category] += q
    end
    cat_hash
  end

  # Adds equipment model id to items hash
  def add_item(equipment_model, _quantity = nil)
    return if equipment_model.nil?
    key = equipment_model.id
    items[key] = items[key] ? items[key] + 1 : 1
  end

  def edit_cart_item(equipment_model, quantity)
    return if equipment_model.nil?
    return if quantity < 0
    key = equipment_model.id
    items[key] = items[key] ? quantity : 0
    self.items = items.except(key) if items[key] == 0
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
    reservations
  end

  def reserve_all(user, res_notes = '', request = false)
    # reserve all the items in the cart!
    # takes 3 arguments which is the current user, whether or not
    # the equipment should be requested or reserved,
    # and what notes the reservations should be initialized with
    reservations = prepare_all
    msgs = []

    if request
      reservations.each { |r| msgs << create_request(r, user, res_notes) }
    else
      reservations.each { |r| msgs << create_reservation(r, user, res_notes) }
    end

    purge_all

    msgs.join(' ') # return flash message
  end

  def request_all(user, notes = '')
    reserve_all(user, notes, true)
  end

  # Returns the cart's duration
  def duration # in days
    @due_date - @start_date + 1
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

  private

  # create a reservation with the appropriate notes and update the message
  # array appropriately; returns the updated message array
  def create_reservation(res, user, res_notes)
    errors = res.validate
    notes = "### Reserved on #{Time.zone.now.to_s(:long)} by "\
          "#{user.md_link} for #{res.reserver.md_link}"
    notes += "\n\n#### Notes:\n#{res_notes}" unless res_notes.nil? ||
                                                    res_notes.empty?
    res.status = 'reserved'
    res.notes = notes
    res.save!

    if AppConfig.get(:notify_admin_on_create) # send e-mail if configured to
      AdminMailer.reservation_created_admin(res).deliver_now
    end
    "Reservation for #{res.equipment_model.md_link} created "\
      "successfully#{', even though ' + errors.to_sentence[0, 1].downcase\
      + errors.to_sentence[1..-1] unless errors.empty?}.\n"
  end

  # create a request with the appropriate notes and update the message array
  # appropriately; returns the updated message array
  def create_request(res, user, res_notes)
    errors = res.validate
    notes = "### Requested on #{Time.zone.now.to_s(:long)} by "\
      "#{user.md_link}\n\n#### Notes:\n#{res_notes}"
    res.flag(:request)
    res.status = 'requested'
    res.notes = notes
    res.save!

    AdminMailer.request_filed(res).deliver_now # send request notification
    "Request for #{res.equipment_model.md_link} filed successfully. "\
      "#{errors.to_sentence}\n"
  end
end
