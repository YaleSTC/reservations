# frozen_string_literal: true
module ReservationGeneratorHelper
  include ActiveSupport::Testing::TimeHelpers

  def gen_res(random = false)
    r = Reservation.new(status: 'reserved', reserver_id: User.all.sample.id,
                        equipment_model: EquipmentModel.all.sample,
                        notes: FFaker::HipsterIpsum.paragraph(2),
                        start_date: Time.zone.today)
    max_checkout_len = r.equipment_model.maximum_checkout_length
    duration = max_checkout_len -
               rand_val(first: 1, last: max_checkout_len - 1,
                        default: 1, random: random)
    r.due_date = r.start_date + duration.days
    r
  end

  def make_checked_out(res, _ = false)
    res.status = 'checked_out'
    res.checked_out = res.start_date
    res.equipment_item = res.equipment_model.equipment_items.all.sample
    res.checkout_handler_id = User.where('role = ? OR role = ? OR role = ?',
                                         'checkout', 'admin',
                                         'superuser').all.sample.id
  end

  def make_returned(res, random = false)
    make_past(res, random)
    make_checked_out res
    r_date = res.due_date > Time.zone.today ? Time.zone.today : res.due_date
    check_in(res, rand_val(first: res.start_date, last: r_date,
                           default: r_date, random: random))
  end

  def make_overdue(res, random = false)
    make_past(res, random, true)
    make_checked_out res
    res.overdue = true
  end

  def make_returned_overdue(res, random = false)
    make_overdue(res, random)
    return_date = rand_val(first: res.due_date, last: Time.zone.today,
                           default: Time.zone.today, random: random)
    check_in(res, return_date)
  end

  def make_missed(res, random = false)
    make_past(res, random)
    res.status = 'missed'
  end

  def make_archived(res, random = false)
    make_past(res, random) if random && rand < 0.5
    res.status = 'archived'
  end

  def make_requested(res, random = false)
    make_future(res, random) if random && rand < 0.5
    res.status = 'requested'
    res.flag(:request)
  end

  def make_denied(res, random = false)
    make_requested(res, random)
    res.status = 'denied'
  end

  def check_in(res, date)
    res.status = 'returned'
    res.checked_in = date
    res.checkin_handler_id = User.where('role = ? OR role = ? OR role = ?',
                                        'checkout', 'admin',
                                        'superuser').all.sample.id
  end

  def make_past(res, random = false, overdue = false)
    start = overdue ? res.duration.days : 1.day
    past = - rand_val(first: start, last: 1.year,
                      default: start + 1.week, random: random)
    offset(res, past)
    # save on the start date so validations run properly
    travel_to(res.start_date) { res.save }
  end

  def make_future(res, random = false)
    # set the amount of time in the future
    future = rand_val(first: 1.day, last: 3.months,
                      default: 1.week, random: random)
    offset(res, future)
  end

  def offset(res, size)
    len = res.duration.days
    res.start_date = res.start_date.days_since(size)
    res.due_date = res.start_date + len
  end

  def rand_val(first:, last:, default:, random: false)
    return default unless random
    rand(first..last)
  end
end
