class Report
  attr_accessor :columns, :row_item_type, :rows
  DEFAULT_COLUMNS = [ ['Total', :all, :count],
                      ['Reserved', :reserved, :count],
                      ['Checked Out', :checked_out, :count],
                      ['Overdue', :overdue, :count],
                      ['Returned On Time', :returned_on_time, :count],
                      ['Returned Overdue', :returned_overdue, :count],
                      ['User Count', :all, :count, :reserver_id] ]
  RES_COLUMNS = [ ['Reserver', :all, :name, :reserver],
                  ['Equipment Model', :all, :name, :equipment_model],
                  ['Equipment Object', :all, :name, :equipment_object],
                  ['Status', :all, :display, :status],
                  ['Start Date', :all, :display, :start_date],
                  ['Checked Out', :all, :display, :checked_out],
                  ['Due Date', :all, :display, :due_date],
                  ['Checked In', :all, :display, :checked_in] ]

  class Column
    attr_accessor :name, :res_set, :data_type, :filter, :data_field
    def self.arr_to_col arr
      c = self.new
      c.name = arr[0]
      c.filter = arr[1]
      c.data_type = arr[2]
      c.data_field = arr[3]
      c
    end
  end

  class Row
    attr_accessor :name, :link_path, :item_id, :data
    def self.item_to_row item
      include Rails.application.routes.url_helpers
      r = Row.new
      begin
        r.name = item.name
        r.link_path = subreport_path(id: item.id, 
                                     class: row_item_type[0...-3])
      rescue # only item without name are reservations
        r.name = item.id
        r.link_path = reservation_path(id: item.id)
      end
      r.item_id = item.id
      r
    end

  end

  # -- Private class helper methods -- #

  def self.average2 arr
    arr = arr.reject { |e| e.nil? }
    if arr.size == 0
      'N/A'
    else
      (arr.inject { |r, e| r + e }.to_f / arr.size).round(2)
    end
  end
    
  def self.avg_duration res_set
    average2(res_set.collect { |r| r.duration })
  end

  def self.avg_time_out res_set
    average2(res_set.collect { |r| r.time_checked_out })
  end

  def self.count_unique(res_set, type)
    # count the # of occurences of unique <type>s in the reservation set,
    # eg how many unique reservers there are in the set
    items = res_set.collect do |res|
      res.send(type)
    end
    items.uniq.count
  end

  def self.calculate(res_set, type, field = nil)
    # given an array of reservations, calculate some data
    case type
    when :count
      return res_set.count if field.nil?
      return count_unique(res_set, field)
    when :duration
      return avg_duration res_set
    when :time_checked_out
      return avg_time_out res_set
    when :display
      return res_set[0].send(field)
    when :name
      item = res_set[0].send(field)
      return item.nil? ? nil : item.name
    end
  end
  
  def self.get_class(symbol)
    # convert a symbol id field to a class, eg :user_id -> User
    return Reservation if symbol == :id
    return User if symbol == :reserver_id
    symbol.to_s[0...-3].camelize.constantize
  end

  
  # build the skeleton of the report.
  # name is used for display, row_item_type must be a symbol
  # of an ID field that the reservation can respond to (eg, :reserver_id)
  # path_method is the method that should be used on the links
  # reservations is the ActiveRecord::Relation of the reservations to consider
  # columns is an array of 3 element arrays used to build the column objects
  # this is so that code outside of the model can interface with this method
  # without having to use a custom data structure

  def self.build_new(row_item_type, reservations = Reservation.all,
                     columns = DEFAULT_COLUMNS)
    report = self.new
    report.row_item_type = row_item_type

    # convert array of column attributes into column objects
    report.columns = columns.collect do |col|
      Column.arr_to_col col
    end

    # get the reservations for each column
    report.columns.each do |col|
      col.res_set = reservations.send(col.filter)
    end

    # set the row objects
    item_ids = reservations.collect(&row_item_type).reject { |e| e.nil? } 
    items = get_class(row_item_type).find(item_ids)

    report.rows = items.collect do |item|
      Row.item_to_row item
    end

    report.populate_data
    report
  end
    
  # -- Instance methods -- #

  def populate_data
    # populate the reports' rows.data 
    # iterate by row
    @rows.each do |row|
      row.data = []
      @columns.each do |col|
        # get all the reservations in the set that are relevant
        # to the row object we're looking at
        res_set = col.res_set.select do |res|
          row.item_id == res.send(@row_item_type)
        end
        # add the datum to the array
        row.data << Report.calculate(res_set, col.data_type, col.data_field)
      end
    end
  end

end
