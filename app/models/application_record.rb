# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.paperclip_url(filename: ':basename')
    if ENV['ENABLE_PAPERCLIP_S3'].present?
      return Paperclip::Attachment.default_options[:url]
    end
    class_plural = to_s.underscore.pluralize
    "/attachments/#{class_plural}/:attachment/:id/:style/#{filename}.:extension"
  end
end
