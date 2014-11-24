# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def markdown(text)
    return "" if text.blank?
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
  def make_deactivate_btn(model_symbol, model_object)
    if model_object.deleted_at
      link_to "Activate", [:activate, model_object], class: "btn btn-success", method: :put
    else
      # handle equipment object-specific code
      # this should ideally be in a separate method
      if model_symbol == :equipment_objects
        em = model_object.equipment_model
        res = model_object.current_reservation
        overbooked_dates = []
        for date in Date.current..Date.current+7.days
          overbooked_dates << date.to_s(:short) if em.available_count(date) <= 0
        end
        onclick_str = "handleDeactivation(this, #{res ? res.id : 'null'}, #{overbooked_dates});"
      end
      link_to "Deactivate", [:deactivate, model_object],
        class: "btn btn-danger", method: :put,
        onclick: "#{onclick_str}"
    end
  end

  def intify(integer)
    return 'unrestricted' if integer.nil? || integer == Float::INFINITY
    integer
  end

  def dayify(integer)
    return 'unrestricted' if integer.nil? || integer == Float::INFINITY
    pluralize(integer, 'day')
  end
end
