class Report # rubocop:disable ClassLength, it's only 105/100
  attr_accessor :columns, :row_item_type, :rows
  DEFAULT_COLUMNS = [['Total', :all, :count],
                     ['Reserved', :reserved, :count],
                     ['Checked Out', :checked_out, :count],
                     ['Overdue', :overdue, :count],
                     ['Returned On Time', :returned_on_time, :count],
                     ['Returned Overdue', :returned_overdue, :count],
                     ['User Count', :all, :count, :reserver_id]]

  # Reports are extremely powerful 2D reservation statistics tables
  # See #build_new for the main constructor method used in the controller.
  #

  # The Column class contains all the information needed to build the
  # columns (obviously I should hope!). Simple arrays can be made into
  # Column objects if their elements are in the right order.
  #
  #   name:       human readable name
  #   filter:     filtering scope to apply to Reservations
  #   data_type:  how to display the data
  #   data_field: what field of data to use
  #   res_set:    ActiveRecord::Relation holding all relevant reservations

  class Column
    attr_accessor :name, :res_set, :data_type, :filter, :data_field
    def self.arr_to_col(arr)
      c = new
      c.name = arr[0]
      c.filter = arr[1]
      c.data_type = arr[2]
      c.data_field = arr[3]
      c
    end
  end

  # Rows correspond to singular objects like equipment models or users.
  # You can even construct a row skeleton with one of these objects
  #
  #   name:      human readable name
  #   link_path: clickable link path
  #   item_id:   the id of the ite
  #   data:      an array of the row's data

  class Row
    attr_accessor :name, :link_path, :item_id, :data
    def self.item_to_row(item)
      r = Row.new
      r.link_path = Rails.application.routes.url_helpers.subreport_path(
        id: item.id, class: item.class.to_s.underscore.downcase)
      begin
        r.name = item.name
            rescue NoMethodError # only item without name are reservations
              r.name = item.id
              r.link_path = Rails.application.routes.url_helpers
                .reservation_path(id: item.id)
      end
      r.item_id = item.id
      r
    end
  end

  # -- Private class helper methods -- #

  # get the average of an array of values, discounting nil values
  def self.average2(arr)
    arr = arr.reject(&:nil?)
    if arr.size == 0
      'N/A'
    else
      (arr.inject { |a, e| a + e }.to_f / arr.size).round(2)
    end
  end

  def self.avg_duration(res_set)
    average2(res_set.collect(&:duration))
  end

  def self.avg_time_out(res_set)
    average2(res_set.collect(&:time_checked_out))
  end

  # count the # of occurences of unique <type>s in the reservation set,
  # eg how many unique reservers there are in the set
  def self.count_unique(res_set, type)
    items = res_set.collect do |res|
      res.send(type)
    end
    items.uniq.count
  end

  # given the narrowed set of reservations, calculate the value
  # according to type and optional field
  # rubocop:disable CyclomaticComplexity
  def self.calculate(res_set, type, field = nil)
    case type
    when :count
      return res_set.count if field.nil?
      count_unique(res_set, field)
    when :duration
      avg_duration res_set
    when :time_checked_out
      avg_time_out res_set
    when :display
      res_set[0].send(field)
    when :name
      item = res_set[0].send(field)
      item.nil? ? nil : item.name
    end
  end
  # rubocop:enable CyclomaticComplexity

  # convert a symbol id field to a class, eg :user_id -> User
  def self.get_class(symbol)
    return Reservation if symbol == :id
    return User if symbol == :reserver_id
    symbol.to_s[0...-3].camelize.constantize
  end

  # Create a new report using an item_type (this is a symbol like
  #   :equipment_model_id
  # a set of reservations (do all your date filtering and stuff here)
  # and an array of columns. Each column object in the array is not
  # actually an instance of the Column class (this method does the
  # conversion) but a 3 or 4 element array literal. See DEFAULT_COLUMNS
  # for an example and Column.arr_to_col for the conversion specifics
  #
  # I wrote the code this way so that we don't need to expose the
  # Column class and because the const array literal declarations
  # are pretty easy to read

  def self.build_new(row_item_type, reservations = Reservation.all,
                     columns = DEFAULT_COLUMNS)
    report = new
    report.row_item_type = row_item_type

    if row_item_type == :category_id
      # some SQL magic to get the category id into the
      # reservation record relation without having to load all
      # the equipment models into memory
      reservations = reservations.with_categories
    end

    report.initialize_columns(columns, reservations, row_item_type)

    # set the row objects
    item_ids = reservations.collect(&row_item_type).reject(&:nil?)
    items = get_class(row_item_type).find(item_ids)

    report.rows = items.collect do |item|
      Row.item_to_row item
    end

    report.populate_data
    report
  end

  # -- Instance methods -- #

  def initialize_columns(col_array, reservations, row_item_type)
    self.columns = col_array.collect do |col|
      Column.arr_to_col col
    end

    # get the reservations for each column
    columns.each do |col|
      # only instantiate the fields that we need
      relation  = reservations.send(col.filter)
      if col.data_type == :count && col.data_field.nil?
        col.res_set = relation.collect(&row_item_type)
      else
        col.res_set = relation.to_a
      end
    end
  end

  def populate_data
    # populate the reports' rows.data
    # iterate by row
    @rows.each do |row|
      row.data = []
      @columns.each do |col|
        # get all the reservations in the set that are relevant
        # to the row object we're looking at
        id = row.item_id
        if col.data_type == :count && col.data_field.nil?
          # do a fast select if we don't care about the other fields
          res_set = col.res_set.select do |res|
            id == res
          end
        else
          res_set = col.res_set.select do |res|
            id == res.send(@row_item_type)
          end
        end
        # add the datum to the array
        row.data << Report.calculate(res_set, col.data_type, col.data_field)
      end
    end
    @columns.each do |col|
      col.res_set = []
    end
  end
end
