# These helper methods can be called in your template to set variables to be used in the layout
# This module should be included in all views globally,
# to do so you may need to add this line to your ApplicationController
#   helper :layout
module LayoutHelper
  def title(page_title, show_title = true)
    content_for(:title) { page_title.to_s }
    @show_title = show_title
  end
  
  def subtitle (page_subtitle, show_subtitle = true)
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
    @favicon_path = "favicon.ico"
  end
  
  def reservations_count
    if current_user.is_admin? || current_user.is_checkout_person?
      @count = Reservation.where(:checked_in => nil).size
    else
      @count = Reservation.where(:reserver_id => current_user.id).size
    end
  end
  
  def navigation_active controller_path
    if current_page?(controller_path)
      @active = 'class=active'
    end
  end
end
