module Autocomplete
  def get_autocomplete_items(parameters)
    query = '%' + parameters[:term].downcase + '%'
    User.where(
      'nickname LIKE ? OR first_name LIKE ? OR last_name LIKE ? OR username '\
      'LIKE ? OR CONCAT_WS(" ",first_name,last_name) LIKE ? OR '\
      'CONCAT_WS(" ",nickname,last_name) LIKE ?', query, query, query, query,
      query, query)
  end
end
