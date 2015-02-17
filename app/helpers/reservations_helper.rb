module ReservationsHelper
  def filter_message(set, source, filter, view_all)
    if view_all
      "Viewing all #{filter} reservations"
    else
      "#{set[filter]} of #{source[filter]} "\
      "#{filter.to_s.humanize.downcase} reservations begin between "\
      'the specified dates'
    end
  end

  def reservation_length
    @reservation_length =
      (@reservation.due_date - @reservation.start_date).to_i
  end

  def bar_progress_res
    define_width_res
    number_to_percentage(@width * 100 || 0, precision: 0)
  end

  def reservation_length_in_words
    if @reservation_length == 0
      'same day'
    else
      distance_of_time_in_words(@reservation.start_date,
                                @reservation.due_date + 1.days)
    end
  end

  def bar_span_positioning_fix
    style = ''

    if reservation_length_in_words == 'same day' || reservation_length > 31
      style << 'bottom: 0;'
    end

    style << 'display: none;' if @width == 0
    style
  end

  def manage_reservations_btn # rubocop:disable all
    return if (cannot? :manage, Reservation) || @reservation.reserver.id.nil?
    if (can? :override, :reservation_errors) &&
       @reservation.approval_status == 'requested'
      link_to 'Review Request', review_request_path, class: 'btn btn-default'
    elsif @reservation.status == 'reserved'
      link_to 'Check-Out',
              manage_reservations_for_user_path(@reservation.reserver.id,
                                                anchor: 'check_out_row'),
              class: 'btn btn-default'
    elsif @reservation.status == 'checked out' ||
          @reservation.status == 'overdue'
      link_to 'Check-In', manage_reservations_for_user_path(
      @reservation.reserver.id,
      anchor: 'check_in_row'), class: 'btn btn-default'
    end
  end

  private

  # the "+ 1" terms are to account for the fact that the first
  # day is counted as part of the length of the reservation.
  def define_width_res
    passed_length = Time.zone.today - @reservation.start_date + 1
    total_length = @reservation.due_date - @reservation.start_date + 1
    # necessary to prevent division by 0
    total_length = total_length == 0 ? 1 : total_length
    @width = passed_length / total_length

    if @width > 1
      @width = 1
    elsif @width < 0
      @width = 0
    else
      @width
    end
  end
end
