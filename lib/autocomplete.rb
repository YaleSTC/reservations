module Autocomplete
  def get_autocomplete_items(parameters)
    query = '%' + parameters[:term].downcase + '%'
    User.where('nickname LIKE ? OR first_name LIKE ? OR last_name LIKE ? OR login LIKE ?', query, query, query, query).reject {|user| ! user.deleted_at.nil?}
  end
end