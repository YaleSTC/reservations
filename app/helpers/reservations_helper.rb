module ReservationsHelper
  def reservation_length
   @reservation_length = (@reservation.due_date.to_date - @reservation.start_date.to_date).to_i
  end

  def bar_progress
    define_width
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
    'bottom: 0' if reservation_length_in_words == 'same day'
  end

  private

    def define_width
      # numerator = number of days passed since start date less than or equal to the due date

      # denominator
      # @reservation_length

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