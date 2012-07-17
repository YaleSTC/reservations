class Cart
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validates :reserver_id, :start_date, :due_date, :presence => true

  validate :start_date_before_due_date?, :not_in_past?,
           :allowable_number_category?, :allowable_number_equipment_model?,
           :duration_allowed?, :no_overdue_reservations?, :available?

  attr_accessor :reserver_id, :items, :start_date, :due_date
  attr_reader   :errors

  def initialize
    @errors = ActiveModel::Errors.new(self)
    @items = []
    @start_date = Date.today
    @due_date = Date.today + 1.day
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

  ## End of functions for error handling

  def add_equipment_model(equipment_model)
    unless item_not_blacked_out?
      errors.add(:start_date, "dates are blacked out")
      return false
    end
    current_item = nil
    @items.find do |item|
      current_item = item if item.equipment_model_id == equipment_model.id
    end
    if current_item
      current_item.increment_quantity
    else
      current_item = CartItem.new(equipment_model.id)
      @items << current_item
    end
    if !current_item.available?(@start_date..@due_date)
      errors.add(:start_date, "is before item is available")
    end 
    #if blacked_out
    # errors.add(
    #end
    return current_item if self.valid?
    self.valid?
  end

  def remove_equipment_model(equipment_model)
    current_item = nil
    @items.find do |item|
      current_item = item if item.equipment_model_id == equipment_model.id
    end
    current_item.decrement_quantity
    if current_item.quantity == 0
      @items.delete(current_item)
    end
    current_item
  end

  def get_cart_items
    items = []
    @items.each do |item|
      items << item.details
    end
    items
  end

  def total_items
    @items.sum{ |item| item.quantity }
  end

  def empty?
    @items.empty?
  end

  def set_start_date(date)
    @start_date = date
    fix_due_date
  end

  def set_due_date(date)
    @due_date = date
    fix_due_date
  end

  def set_reserver_id(user_id)
    @reserver_id = user_id
  end

  def duration #in days
    @due_date - @start_date + 1
  end

  def reserver
    reserver = User.include_deleted.find(@reserver_id)
  end

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
  

  ## VALIDATIONS ##

  ## Date Validations

  # Checks all date-related validations
  def valid_dates?
    valid = true
    valid = false if !not_in_past?
    valid = false if !start_date_before_due_date?
    valid = false if !duration_allowed?
    valid = false if !available?
    valid = false if !item_not_blacked_out?
  end

  # Checks that neither start date nor due date are in the past
  def not_in_past?
    in_past = false
    if start_date < Date.today
      in_past = true
      errors.add(:start_date, "Start date cannot be before today")
    end
    if due_date < Date.today
      in_past = true
      errors.add(:due_date, "Due date cannot be before today")
    end
    return !in_past
  end

  # Checks that start date is before due date
  def start_date_before_due_date?
    if start_date > due_date
      errors.add(:due_date, "Due date cannot be before start date.")
      return false
    end
    return true
  end

  # Check that the duration is not longer than the maximum checkout length for any of the item
  def duration_allowed?
    is_too_long = false
    @items.each do |item|
      eq_model = item.equipment_model
      category = eq_model.category
      unless category.max_checkout_length.nil? || self.duration <= category.max_checkout_length
        errors.add(:items, "You can only check out " + eq_model.name + " for " + category.max_checkout_length.to_s + " days")
        is_too_long = true
      end
    end
    !is_too_long
  end

  # Check that all items are available
  def available?
    available = true
    return false if start_date.nil? or due_date.nil?
    @items.each do |item|
      if !item.available?(start_date..due_date)
        errors.add(:items, item.name + " is not available for all or part of the reservation length.")
        available = false
      end
    end
    available
  end

  ## Item validations
  # Check if the user should renew their existing reservation rather than creating a new one
  def no_renewable_models?
    none_to_renew = true
    reservations_to_renew = renewable_reservations
    
    eq_model_names = reservations_to_renew.collect {|r| EquipmentModel.include_deleted.find(r.equipment_model_id).name}.uniq
    
    unless reservations_to_renew.empty?
      eq_model_names.each do |eq_model_name|
        errors.add(:items, reserver.name + " should renew " + eq_model_name)
        none_to_renew = false
      end
    end
    return none_to_renew
  end
  
  #Check that the reserver does not exceeds the maximum number of any equipment models
  def allowable_number_equipment_model?
    too_many = false
    reserver_model_counts = reserver.checked_out_models
    @items.each do |item|
      #If the reserver has none of the model checked out, count = 0
      eq_model = item.equipment_model
      curr_model_count = reserver_model_counts[eq_model.id]
      curr_model_count ||= 0
      # This thing with unrestricted makes me upset
      if eq_model.maximum_per_user != "unrestricted"
        unless eq_model.maximum_per_user >= item.quantity + curr_model_count
          errors.add(:items, reserver.name + " has too many of " + eq_model.name)
          too_many = true
        end
      end
    end
    !too_many
  end

  # Check that the reserver does not exceeds the maximum number of any equipment models
  def allowable_number_category?
    too_many = false
    # Creates a hash of the number of models a reserver has checked out
    # e.g. {model_id1 => count1, model_id2 => count2}
    h = reserver.checked_out_models

    # Make a hash of the reserver's counts for each category
    # e.g {category1=>cat1_count, category2 =>cat2_count} for the reserver
    eq_models = EquipmentModel.include_deleted.find(h.keys)
    reserver_categories = eq_models.collect{|model| model.category_id}.uniq
    reserver_cat_and_counts_arr = reserver_categories.collect do |category_id|
      count = 0
      eq_models.each do |model|
        count += h[model.id] if model.category_id == category_id
      end
      [category_id, count]
    end

    reserver_category_counts = Hash[*reserver_cat_and_counts_arr.flatten]

    # Make a hash of the cart's counts for each category
    # e.g. {category1=>cat1_count, category2 =>cat2_count} for the cart
    cart_categories = @items.collect {|item| item.equipment_model.category_id}.uniq
    cart_cat_and_counts_arr = cart_categories.collect do |category_id|
      count = 0
      @items.each do |item|
        count += item.quantity if item.equipment_model.category_id == category_id
      end
      [category_id, count]
    end
    cart_cat_counts = Hash[*cart_cat_and_counts_arr.flatten]

    # Test each of the categories to see if the reserver exceeds the limit
    cart_categories.each do |category_id|
      curr_cat_reserver_count = reserver_category_counts[category_id]
      curr_cat_reserver_count ||= 0
      curr_cat = Category.include_deleted.find(category_id)
    if curr_cat.maximum_per_user != "unrestricted"
        # Sum the number of items for a category in the cart and the number of items in a category a reserver has out
        unless curr_cat.maximum_per_user >= cart_cat_counts[category_id] + curr_cat_reserver_count
          errors.add(:items, reserver.name + " has too many " + curr_cat.name)
          too_many = true
        end
      end
    end
    !too_many
  end

  def duration_allowed?
    is_too_long = false
    @items.each do |item|
      eq_model = item.equipment_model
      category = eq_model.category
      unless category.max_checkout_length.nil? || self.duration <= category.max_checkout_length
        errors.add(:items, "You can only check out " + eq_model.name + " for " + category.max_checkout_length.to_s + " days")
        is_too_long = true
      end
    end
    !is_too_long
  end

  #Need to include check in case there are no items currently in cart.

  # Check that the item is not blacked out on the dates it is being reserved for
  def item_not_blacked_out?
    flag = true
    if (a = BlackOut.date_is_blacked_out(start_date))
       errors.add(:start_date, a.notice)
       if (a.black_out_type_is_hard)
         flag = false
       end
    elsif (a = BlackOut.date_is_blacked_out(due_date))
       errors.add(:due_date, a.notice)
       if (a.black_out_type_is_hard)
         flag = false
       end
    end 
    return flag
  end

 
  # User Validation

 # Check that reserver has no overdue reservations
  def no_overdue_reservations?
    unless !reserver.reservations.overdue_reservations?(reserver)
      errors.add(:reserver_id, reserver.name + " has overdue reservations")
      return false
    end
    return true
  end
end
