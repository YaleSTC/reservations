# Migration courtesy of Thoughtbot Migration Guide
# https://github.com/thoughtbot/paperclip/blob/master/MIGRATING.md
class ConvertToActiveStorage < ActiveRecord::Migration[5.2]
  require 'open-uri'

  def up
    # mariadb
     get_blob_id = 'LAST_INSERT_ID()'

    active_storage_blob_statement = ActiveRecord::Base.connection.raw_connection.prepare("
      INSERT INTO active_storage_blobs (
        `key`, filename, content_type, metadata, byte_size, checksum, created_at
      ) VALUES (?, ?, ?, '{}', ?, ?, ?)
    ")

    active_storage_attachment_statement = ActiveRecord::Base.connection.raw_connection.prepare("
      INSERT INTO active_storage_attachments (
        name, record_type, record_id, blob_id, created_at
      ) VALUES (?, ?, ?, #{get_blob_id}, ?)
    ")

    Rails.application.eager_load!
    models = ActiveRecord::Base
      .descendants
      .select{ |name| name.to_s.match('EquipmentModel') || name.to_s.match('AppConfig') }

    transaction do
      models.each do |model|
        attachments = model.column_names.map do |c|
          if c =~ /(.+)_file_name$/
            $1
          end
        end.compact

        if attachments.blank?
          next
        end

        model.find_each.each do |instance|
          attachments.each do |attachment|
            if instance.send(attachment).path.blank?
              next
            end

            active_storage_blob_statement.execute(
                key(instance, attachment),
                instance.send("#{attachment}_file_name"),
                instance.send("#{attachment}_content_type"),
                instance.send("#{attachment}_file_size"),
                checksum(instance.send(attachment)),
                instance.updated_at.strftime('%Y-%m-%d %H:%M:%S')
              )

            active_storage_attachment_statement.execute(
                attachment,
                model.name,
                instance.id,
                instance.updated_at.strftime('%Y-%m-%d %H:%M:%S')
              )
          end
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def key(instance, attachment)
    SecureRandom.uuid
  end

  def checksum(attachment)
    # local files stored on disk:
    url = attachment.path
    Digest::MD5.base64digest(File.read(url))

    # remote files stored on S3:
    # url = "http:#{attachment.url}"
    # Digest::MD5.base64digest(Net::HTTP.get(URI(url)))
  end
end
