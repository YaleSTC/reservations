# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# Adapted from
# medium.com/@celik4mehmet/activestorage-how-to-change-storage-and-sync-files-72a8a872d253
# rubocop:enable Metrics/LineLength
namespace :active_storage do
  desc 'Migrate ActiveStorage files from local to Amazon S3'
  task mirror: :environment do
    ActiveStorage::Blob.all.each do |blob|
      local_file = ActiveStorage::Blob.service.primary.path_for(blob.key)
      blob.service.mirrors.each do |mirror|
        begin
          unless mirror.exist? blob.key
            mirror
              .upload(blob.key,
                      File.open(local_file),
                      checksum: blob.checksum)
          end
        rescue
          puts 'cannot find the file'
        end
      end
    end
  end
end
