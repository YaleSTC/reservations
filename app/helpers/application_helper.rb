# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def markdown(text)
    rndr = Redcarpet::Render::HTML.new(:filter_html => true, :safe_links_only => true, :with_toc_data => true, :hard_wrap => true, :no_images => true)
    markdown = Redcarpet::Markdown.new(rndr, :autolink => true, :space_after_headers => true, :fenced_code_blocks => true, :no_intra_emphasis => true, :strikethrough => true, :superscript => true)
    markdown.render(text).html_safe
  end

  def paperclip_field_error(local_form_variable, *fields)
    # binding.pry
    # Field must be symbol
    fields.each do |field|
      unless local_form_variable.error(field).blank?
        return 'error'
      end
    end
  end
  
end