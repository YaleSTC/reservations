# frozen_string_literal: true
# rubocop:disable ModuleLength
module EquipmentImport
  # IMPORT FUNCTIONS - these are all kinda similar, but we'll write them
  # separately for now and we can always refactor later.

  # import categories
  # rubocop:disable MethodLength
  def import_cats(processed_cats, cat_overwrite = false)
    # let's make sure that we're consistent w/ scope on these variables
    array_of_success = [] # will contain category items
    array_of_fail = [] # will contain category_data hashes and error messages

    processed_cats.each do |cat_data|
      cat_data[:csv_import] = true

      # pick or create new category based on overwrite parameter
      cat = if cat_overwrite &&
               !Category.where('name = ?', cat_data[:name]).empty?
              Category.where('name = ?', cat_data[:name]).first
            else
              Category.new(cat_data)
            end

      cat.update_attributes(cat_data)
      # if updated / new category is valid, save to database and add to array
      # of success
      if cat.valid?
        cat.save
        array_of_success << cat
      # else, store to array of fail with error messages
      else
        array_of_fail << [cat_data,
                          cat.errors.full_messages.to_sentence.capitalize\
                          + '.']
      end
    end

    # return hash of status arrays
    { success: array_of_success, fail: array_of_fail }
  end
  # rubocop:enable MethodLength

  # import models
  # rubocop:disable MethodLength, PerceivedComplexity
  def import_models(processed_models, model_overwrite = false)
    # let's make sure that we're consistent w/ scope on these variables
    array_of_success = [] # will contain model items
    array_of_fail = [] # will contain model_data hashes and error messages

    processed_models.each do |model_data|
      model_data[:csv_import] = true

      # check for valid category and store id in relevant parameter (nil if
      # no category found)
      model_data[:category] =
        Category.where('name = ?', model_data[:category]).first

      # pick or create new model based on overwrite parameter
      model = if model_overwrite &&
                 !EquipmentModel.where('name = ?', model_data[:name]).empty?
                EquipmentModel.where('name = ?', model_data[:name]).first
              else
                EquipmentModel.new(model_data)
              end

      model.update_attributes(model_data)
      # if updated / new model is valid, save to database and add to array of
      # success
      if model.valid?
        model.save
        array_of_success << model
      # else, store to array of fail with error messages
      else
        error = if model_data[:category].nil?
                  'Category not found.'
                else
                  model.errors.full_messages.to_sentence.capitalize + '.'
                end
        array_of_fail << [model_data, error]
      end
    end

    # return hash of status arrays
    { success: array_of_success, fail: array_of_fail }
  end
  # rubocop:enable MethodLength, PerceivedComplexity

  # import items
  def import_items(processed_items) # rubocop:disable MethodLength
    # let's make sure that we're consistent w/ scope on these variables
    array_of_success = [] # will contain items
    array_of_fail = [] # will contain item_data hashes and error messages

    processed_items.each do |item_data|
      item_data[:csv_import] = true

      # check for valid equipment_model and store id in relevant parameter (
      # nil if no category found)
      item_data[:equipment_model] =
        EquipmentModel.where('name = ?', item_data[:equipment_model]).first

      # create new category
      item = EquipmentItem.new(item_data)
      item.assign_attributes(item_data)

      # if new item is valid, save to database and add to array of success
      if item.valid?
        item.notes = "#### Created at #{Time.zone.now.to_s(:long)} via import"
        item.save
        array_of_success << item
      # else, store to array of fail with error messages
      else
        error = if item_data[:equipment_model].nil?
                  'Equipment Model not found.'
                else
                  item.errors.full_messages.to_sentence.capitalize + '.'
                end
        array_of_fail << [item_data, error]
      end
    end

    # return hash of status arrays
    { success: array_of_success, fail: array_of_fail }
  end

  # VALIDATION FUNCTIONS - not sure if this should be here or if we need to
  # create an import model to validate properly (see
  # import_equipment_controller.rb)

  # this is for validations that are true for all imports
  def valid_equipment_import?(processed_stuff, file, type, accepted_keys,
                              key_error)
    # check for file
    unless file
      flash[:error] = 'Please select a file to upload'
      return false
    end

    # check for total CSV import failure
    if processed_stuff.nil?
      flash[:error] = "Unable to import #{type} CSV file.  Please ensure it "\
        'matches the import format, and try again.'
      return false
    end

    # check for valid keys, ensure we don't raise a NoMethodError
    unless processed_stuff.first && processed_stuff.first.keys == accepted_keys
      flash[:error] = key_error
      return false
    end

    true
  end

  # these next few methods are all very similar, not sure if there's a better
  # way but we'll start with this.
  # category validators
  def valid_cat_import?(processed_cats, cat_file)
    # define accepted keys and key error
    # NOTE: this must match the parameters in the database / model!!
    accepted_keys = [:name, :max_per_user, :max_checkout_length,
                     :max_renewal_times, :max_renewal_length,
                     :renewal_days_before_due, :sort_order]
    key_error = 'Unable to import category CSV file. Please ensure that the '\
      'first line of the file exactly matches the sample input (name, '\
      'max_per_user, etc.) Note that headers are case sensitive and must be '\
      'in the correct order.'
    # general validations
    if valid_equipment_import?(processed_cats, cat_file, 'category',
                               accepted_keys, key_error)
      # custom validators for categories go here
      return true
    else
      return false
    end
  end

  # model validators
  def valid_model_import?(processed_models, model_file)
    # define accepted keys and key error
    accepted_keys = [:category, :name, :description, :late_fee,
                     :replacement_fee, :max_per_user, :max_renewal_length]
    key_error = 'Unable to import equipment model CSV file. Please ensure '\
      'that the first line of the file exactly matches the sample input ('\
      'category, name, etc.) Note that headers are case sensitive and must '\
      'be in the correct order.'
    # general validations
    if valid_equipment_import?(processed_models, model_file,
                               'equipment model', accepted_keys, key_error)
      # custom validators for equipment models go here
      return true
    else
      return false
    end
  end

  # item validators
  def valid_item_import?(processed_items, item_file)
    # define accepted keys and key error
    accepted_keys = [:equipment_model, :name, :serial]
    key_error = 'Unable to import equipment item CSV file. Please ensure '\
      'that the first line of the file exactly matches the sample input ('\
      'equipment_model,name,serial) Note that headers are case sensitive '\
      'and must be in the correct order.'
    # general validations
    if valid_equipment_import?(processed_items, item_file,
                               'equipment item', accepted_keys, key_error)
      # custom validators for equipment items go here
      return true
    else
      return false
    end
  end
end
