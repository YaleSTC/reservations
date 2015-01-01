# These helper methods can be called in your template to set variables to be
# used in the layout
# This module should be included in all views globally,
# to do so you may need to add this line to your ApplicationController
#   helper :layout
module LayoutHelper
  def title(page_title, show_title = true)
    content_for(:title) { page_title.to_s }
    @show_title = show_title
  end

  def subtitle(page_subtitle, show_subtitle = true)
    content_for(:subtitle) { page_subtitle.to_s }
    @show_subtitle = show_subtitle
  end

  def show_title?
    @show_title
  end

  def stylesheet(*args)
    content_for(:head) { stylesheet_link_tag(*args) }
  end

  def javascript(*args)
    content_for(:head) { javascript_include_tag(*args) }
  end

  def site_title
    @site_title = @app_configs.site_title.strip
  end

  def favicon_path
    @favicon_path = 'favicon.ico'
  end

  # rubocop:disable UselessAssignment
  def reservations_count
    if can? :manage, Reservation
      count = Reservation.active.size
    else
      # this variable is called in _navbar.html.erb to list a user's current
      # reservations in the dropdown.
      @current_reservations = current_or_guest_user.reservations
                              .active_or_requested.includes(:equipment_model)
      count = @current_reservations.size
    end
  end
  # rubocop:enable UselessAssignment

  def equipment_count
    @current_equipment = current_or_guest_user.reservations.checked_out
    @current_equipment.size
  end

  def navigation_active(controller_path)
    return unless current_page?(controller_path)
    @active = 'class=active'
  end

  def get_role_name(role) # rubocop:disable CyclomaticComplexity
    case role
    when 'superuser'
      'Superuser'
    when 'admin'
      'Admin'
    when 'checkout'
      'Checkout Person'
    when 'normal'
      'Patron'
    when 'banned'
      'Banned'
    when 'guest'
      'Guest'
    end
  end
end
