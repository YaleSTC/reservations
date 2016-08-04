require Rails.root.join('spec/support/mockers/mocker.rb')

class AnnouncementMock < Mocker
  def self.klass
    Announcement
  end

  def self.klass_name
    'Announcement'
  end
end
