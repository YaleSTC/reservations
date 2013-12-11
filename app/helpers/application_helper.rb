# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def markdown(text)
    rndr = Redcarpet::Render::HTML.new(filter_html: true, safe_links_only: true, with_toc_data: true, hard_wrap: true, no_images: true)
    markdown = Redcarpet::Markdown.new(rndr, autolink: true, space_after_headers: true, fenced_code_blocks: true, no_intra_emphasis: true, strikethrough: true, superscript: true)
    markdown.render(text).html_safe
  end

  def markdown_to_plain_text(text)
    strip_tags(markdown(text)).html_safe
  end

  def paperclip_field_error(local_form_variable, *fields)
    # Field must be symbol
    fields.each do |field|
      unless local_form_variable.error(field).blank?
        return 'error'
      end
    end
  end

  # model_symbol must be a symbol for the model that is being deactivated, eg --> :equipment_models
  def make_activate_btn(model_symbol, model_object)
    link_to "Activate", activate_path(model_symbol, model_object), class: "btn btn-success", method: :put
  end

  def make_deactivate_btn(model_symbol, model_object)
    link_to "Deactivate", deactivate_path(model_symbol, model_object), class: "btn btn-danger", method: :put, confirm: "Deactivating this #{model_object.class} will permanently destroy all associated reservations, are you sure you want to do this?"
  end
end
