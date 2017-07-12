# frozen_string_literal: true

##
# This concern adds a monthly calendar view of reservations for a given resource
# to a controller. It can be used to provide a standalone view with the
# appropriate routing, but can also be used to insert a `calendar` partial into
# other views. It requires that the `GET :calendar` route be added to the
# relevant resource and that the following (private) methods be implemented:
#
# === generate_calendar_reservations
# This method should return the relevant list of reservations to display in
# the calendar
#
# === generate_calendar_resource
# This method should return the relevant instance of the current controller's
# model (e.g. the equipment model whose calendar is being requested)
#
# === calendar_name_method
# This is the method that will be called to get the title of each "event". It
# is a symbol that will be called on an instance of Reservation whose return
# value should accept a #name method (e.g. `reserver` or `equipment_model`)
module Calendarable
  extend ActiveSupport::Concern

  ##
  # This method responds to requests for /[RESOURCE_ROUTE]/calendar (e.g.
  # /equipment_models/:id/calendar. It responds to three formats - HTML, which
  # is used for the actual page; JSON, which is used to return source data for
  # the FullCalendar calendar; and ICS, which is used to return an
  # iCalendar-compatible calendar for use with Google Calendar.
  def calendar # rubocop:disable AbcSize, MethodLength
    prepare_calendar_vars

    # extract calendar data
    respond_to do |format|
      format.html
      format.json { @calendar_res = generate_calendar_reservations }
      # generate iCal version
      # see https://gorails.com/forum/multi-event-ics-file-generation
      format.ics do
        @calendar_res = generate_calendar_reservations
        cal = Icalendar::Calendar.new

        @calendar_res.each do |r|
          event = Icalendar::Event.new
          event.dtstart = Icalendar::Values::Date.new(r.start_date)
          event.dtend = Icalendar::Values::Date.new(r.end_date + 1.day)
          event.summary = r.reserver.name
          event.location = r.equipment_item.name unless r.equipment_item.nil?
          event.url = reservation_url(r, format: :html)
          cal.add_event(event)
        end
        cal.publish

        response.headers['Content-Type'] = 'text/calendar'
        response.headers['Content-Disposition'] =
          'attachment; filename=reservations.ics'
        render plain: cal.to_ical
      end
    end
  end

  private

  ##
  # Prepares all necessary instance variables for calendar; calls the necessary
  # private methods (see above).
  def prepare_calendar_vars
    @start_date = calendar_start_date
    @end_date = calendar_end_date
    @resource = generate_calendar_resource
    @src_path = generate_source_path
    @name_method = calendar_name_method
  end

  ##
  # Returns the start date for the calendar view / export, defaulting to 6
  # months prior to today and otherwise reading values from either
  # params[:start] (for requests from FullCalendar) or
  # params[:calendar][:start_date] (for export requests).
  def calendar_start_date
    if params[:start]
      Time.zone.parse(params[:start]).to_date
    elsif params[:calendar] && params[:calendar][:start_date]
      Time.zone.parse(params[:calendar][:start_date]).to_date
    else
      Time.zone.today - 6.months
    end
  end

  ##
  # Returns the end date for the calendar view / export, defaulting to 6 months
  # from today and otherwise reading values from either params[:end] (for
  # requests from FullCalendar) or params[:calendar][:end_date] (for export
  # requests).
  def calendar_end_date
    if params[:end]
      Time.zone.parse(params[:end]).to_date
    elsif params[:calendar] && params[:calendar][:end_date]
      Time.zone.parse(params[:calendar][:end_date]).to_date
    else
      Time.zone.today + 6.months
    end
  end

  ##
  # This method should return the relevant list of reservations to display in
  # the calendar
  def generate_calendar_reservations
    raise NotImplementedError
  end

  ##
  # This method should return the relevant instance of the current controller's
  # model (e.g. the equipment model whose calendar is being requested)
  def generate_calendar_resource
    raise NotImplementedError
  end

  ##
  # Returns the Rails URL helper for the current calendar view (used to
  # generate the JSON source URL)
  def generate_source_path
    "calendar_#{@resource.class.to_s.underscore}_path".to_sym
  end

  ##
  # This is the method that will be called to get the title of each "event". It
  # is a symbol that will be called on an instance of Reservation whose return
  # value should accept a #name method (e.g. `reserver` or `equipment_model`)
  def calendar_name_method
    raise NotImplementedError
  end
end
