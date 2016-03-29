require 'spec_helper'

describe AppConfig, type: :model do
  before(:all) { AppConfig.delete_all }
  before(:each) { @ac = FactoryGirl.build(:app_config) }

  it 'has a working factory' do
    expect(@ac.save).to be_truthy
  end
  it 'does not accept empty site title' do
    @ac.site_title = nil
    expect(@ac).not_to be_valid
    @ac.site_title = ' '
    expect(@ac).not_to be_valid
  end
  it 'does not accept too long a site title' do
    @ac.site_title = 'AaaaaBbbbbCccccDddddEeeee'
    expect(@ac).not_to be_valid
  end
  it "shouldn't have an invalid e-mail" do
    emails = ['ana@com', 'anda@pres,com', nil, ' ']
    emails.each do |invalid|
      @ac.admin_email = invalid
      expect(@ac).not_to be_valid
    end
  end
  it 'should have a valid and present e-mail' do
    @ac.admin_email = 'ana@yale.edu'
    expect(@ac).to be_valid
  end
  it "shouldn't have an invalid contact e-mail" do
    emails = ['ana@com', 'anda@pres,com']
    emails.each do |invalid|
      @ac.contact_link_location = invalid
      expect(@ac).not_to be_valid
    end
  end
  # it "has an attachment that could serve as favicon" do
  #   @ac.favicon_file_name = "icon.ico"
  #   @ac.should be_valid
  # end
  # it "does not accept a missing favicon" do
  #   @ac.favicon_file_name = ""
  #   @ac.should_not be_valid
  # end
  it 'has an attachment that is of the favicon format' do
    types = ['image/gif', 'image/jpeg', 'image/png']
    types.each do |invalid|
      @ac.favicon_content_type = invalid
      expect(@ac).not_to be_valid
    end
    @ac.favicon_content_type = 'image/vnd.microsoft.icon'
  end

  context '.contact_email' do
    it 'returns the contact e-mail if it is set' do
      @ac.contact_link_location = 'contact@example.com'
      @ac.save

      expect(AppConfig.contact_email).to eq('contact@example.com')

      AppConfig.delete_all
    end

    it 'returns the admin e-mail if no contact e-mail is set' do
      @ac.contact_link_location = ''
      @ac.save

      expect(AppConfig.contact_email).to eq(AppConfig.check(:admin_email))

      AppConfig.delete_all
    end
  end
end
