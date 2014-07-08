  def validate_dates
    # run on date change
    errors = []
    # blackouts not on date
    errors << "blackout exists on start date" if Blackout.hard_blackout_exists_on_date(@start_date)
    errors << "blackout exists on end date" if Blackout.hard_blackout_exists_on_date(@due_date)
    errors << "overdue reservations" if Reservation.for_reserver(@reserver_id).overdue.count > 0
    # for some reason reserver is submitted at the same time as dates
    errors.concat(self.validate_dates_and_items.to_a)
    return errors
  end

  def validate_items
    # run on item change
    errors = []
    relevant = Reservation.for_reserver(@reserver_id).active
    @items.each do |em_id, quantity|

    end
    #under_max_model_count?

    #under_max_category_count?
    errors.concat(validate_dates_and_items.to_a)
    errors << 'maybe you have an error with items? idk'
    return errors
  end

  def validate_dates_and_items
    # validations that run on both item and date changes
    # available
    # duration
    # not renewable
  end

  def validate_all
    errors = validate_dates
    errors.concat(validate_items.to_a)
    return errors

  end




  ## Item methods

  # Adds equipment model id to items hash
  def add_item(equipment_model)
    return if equipment_model.nil?
    key = equipment_model.id.to_s
    self.items[key] = self.items[key] ? self.items[key] + 1 : 1
  end

  # Remove equipment model id from items hash, or decrement its count
  def remove_item(equipment_model)
    return if equipment_model.nil?
    key = equipment_model.id.to_s
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
