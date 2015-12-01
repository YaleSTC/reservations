# rubocop:disable UselessAssignment
def days_of_the_week_long
  days_of_the_week_long = %w(Sunday, Monday, Tuesday, Wednesday, Thursday,
                             Friday, Saturday)
end

def days_of_the_week_short
  days_of_the_week_short = %w(Sun, Mon, Tues, Wed, Thurs, Fri, Sat)
end

def days_of_the_week_short_with_index
  days_of_the_week_short_with_index = [
    [0, 'Sun'], [1, 'Mon'], [2, 'Tues'], [3, 'Wed'], [4, 'Thurs'], [5, 'Fri'],
    [6, 'Sat']]
end
# rubocop:enable UselessAssignment
