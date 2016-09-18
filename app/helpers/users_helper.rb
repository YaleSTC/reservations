# frozen_string_literal: true
module UsersHelper
  def active_tab(key)
    return 'active' if key == :current_equipment
  end

  def stats_icons(stat) # rubocop:disable CyclomaticComplexity
    return 'fa fa-camera-retro' if stat == :checked_out
    return 'fa fa-list-alt' if stat == :future
    return 'fa fa-exclamation-circle' if stat == :overdue
    return 'fa fa-clock-o' if stat == :past
    return 'fa fa-minus-circle' if stat == :missed
    return 'fa fa-thumbs-down' if stat == :past_overdue
  end

  def make_ban_btn(user)
    return if user == current_user
    if user.role != 'banned'
      link_to 'Ban', ban_user_path(user), class: 'btn btn-danger',
                                          method: :put
    else
      link_to 'Unban', unban_user_path(user), class: 'btn btn-success',
                                              method: :put
    end
  end
end
