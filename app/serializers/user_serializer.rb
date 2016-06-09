class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :nickname, :phone,
             :affiliation, :terms_of_service_accepted, :role,
             :reservation_counts

  def reservation_counts
    res = object.reservations
    counts = { checked_out:  res.checked_out.count,
               overdue:      res.overdue.count,
               future:       res.reserved.count,
               past:         res.returned.count,
               past_overdue: res.returned_overdue.count }
    counts[:missed] = res.missed.count unless AppConfig.check(:res_exp_time)
    counts
  end
end
