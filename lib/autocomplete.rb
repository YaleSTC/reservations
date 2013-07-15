module Autocomplete
  def get_autocomplete_items(parameters)
    parameters[:term] = parameters[:term].downcase
    users = User.select("nickname, first_name, last_name,login, id, deleted_at").reject {|user| ! user.deleted_at.nil?}
    @search_result = []
    users.each do |user|
      if user.login.downcase.include?(parameters[:term]) ||
        user.name.downcase.include?(parameters[:term]) ||
        [user.first_name.downcase, user.last_name.downcase].join(" ").include?(parameters[:term])
        @search_result << user
      end
    end
    users = @search_result
  end
end