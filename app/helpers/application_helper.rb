# frozen_string_literal: true

# Methods added to this helper will be available to all templates in the
# application.
module ApplicationHelper
  def markdown(text, filter = true)
    return '' if text.blank?
    rndr =
      Redcarpet::Render::HTML.new(filter_html: filter, safe_links_only: true,
                                  with_toc_data: true, hard_wrap: true,
                                  no_images: true)
    markdown =
      Redcarpet::Markdown.new(rndr, autolink: true, space_after_headers: true,
                                    fenced_code_blocks: true,
                                    no_intra_emphasis: true,
                                    strikethrough: true, superscript: true)
    # This is safe -- Redcarpet sanitizes
    markdown.render(text).html_safe
  end

  def markdown_to_plain_text(text)
    # This is safe -- Redcarpet sanitizes
    strip_tags(markdown(text)).html_safe
  end

  def paperclip_field_error(local_form_variable, *fields)
    # Field must be symbol
    fields.each do |field|
      return 'error' if local_form_variable.error(field).present?
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

  def paperclip_full_url(upload)
    return '#' unless upload.url
    unless Rails.application.config.action_controller.relative_url_root
      return upload.url
    end
    "#{Rails.application.config.action_controller.relative_url_root}" \
      "#{upload.url}"
  end
end
