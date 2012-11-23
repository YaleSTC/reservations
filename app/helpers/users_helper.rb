module UsersHelper
  def active_tab key
    if key == :current_equipment
      return 'active'
    end
  end
  
  def stats_icons stat
    return 'icon-camera-retro' if stat == :checked_out
    return 'icon-list-alt' if stat == :future
    return 'icon-exclamation-sign' if stat == :overdue
    return 'icon-time' if stat == :past
    return 'icon-minus-sign' if stat == :missed
    return 'icon-thumbs-down' if stat == :past_overdue
  end
end
