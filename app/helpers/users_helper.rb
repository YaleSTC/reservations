module UsersHelper
  def active_tab key
    if key == :current_equipment
      return 'active'
    end
  end
  
  def stats_icons stat
    return 'icon-camera-retro' if stat == :current_equipment
    return 'icon-list-alt' if stat == :current_reservations
    return 'icon-exclamation-sign' if stat == :overdue_equipment
    return 'icon-time' if stat == :past_equipment
    return 'icon-minus-sign' if stat == :missed_reservations
    return 'icon-thumbs-down' if stat == :past_overdue_equipment
  end
end
