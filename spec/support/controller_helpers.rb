# some basic helpers to simulate controller methods in specs
module ControllerHelpers
  def current_user
    user_session_info =
      response.request.env['rack.session']['warden.user.user.key']
    return unless user_session_info
    user_id = user_session_info[0][0]
    User.find(user_id)
  end

  def user_signed_in?
    !current_user.nil?
  end
end
