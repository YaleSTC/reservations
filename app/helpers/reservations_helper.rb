module ReservationsHelper
  def reservation_length
   @reservation_length = (@reservation.due_date.to_date - @reservation.start_date.to_date).to_i
  end

  def bar_progress_res
    define_width_res
    number_to_percentage(@width * 100 || 0, :precision => 0)
  end

  def reservation_length_in_words
    if @reservation_length == 0
      'same day'
    else
      distance_of_time_in_words(@reservation.start_date, @reservation.due_date)
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

  def manage_reservations_btn
    if current_user.can_checkout?
      if @reservation.status == 'reserved'
        link_to 'Check-Out', manage_reservations_for_user_path(@reservation.reserver.id,
          anchor: 'check_out_row'), class: 'btn btn-inverse'
      elsif @reservation.status == 'checked out' || @reservation.status == 'overdue'
        link_to 'Check-In', manage_reservations_for_user_path(@reservation.reserver.id,
          anchor: 'check_in_row'), class: 'btn btn-inverse'
      end
    end

  end

  private

    def define_width_res
      passed_length = Time.now.to_date - @reservation.start_date.to_date
      total_length = @reservation.due_date.to_date - @reservation.start_date.to_date
      total_length = total_length == 0 ? 1 : total_length # necessary to prevent division by 0
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