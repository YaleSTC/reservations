# some basic helpers to simulate controller methods in specs
module ControllerHelpers
  def current_user
    user_session_info = response.request.env['rack.session']['warden.user.user.key']
    if user_session_info
      user_id = user_session_info[0][0]
      User.find(user_id)
    else
      nil
    end
  end

  def user_signed_in?
    !!current_user
  end
end
