require 'spec_helper'

shared_examples_for 'successful upload' do |filename|
  before do
    file = fixture_file_upload(filename, 'text/csv')
    post :import, csv_upload: file
  end
  it { is_expected.to respond_with(:success) }
  it { is_expected.not_to set_flash }
end

shared_examples_for 'failure' do
  it { is_expected.to redirect_to('where_i_came_from') }
  it { is_expected.to set_flash }
end

describe ImportUsersController, type: :controller do
  before(:each) { mock_app_config }

  before(:each) do
    sign_in FactoryGirl.create(:admin)
    request.env['HTTP_REFERER'] = 'where_i_came_from'
  end

  describe '#import (POST /import_users/imported)' do
    context 'when the csv is valid' do
      it_behaves_like 'successful upload', 'valid_users.csv'
    end
    context 'when the csv contains invalid UTF-8' do
      it_behaves_like 'successful upload', 'invalid_utf8_users.csv'
    end
    context 'when the header line has spaces' do
      it_behaves_like 'successful upload', 'header_spaces_users.csv'
    end
    context 'with extra blank columns' do
      it_behaves_like 'successful upload', 'extra_columns_users.csv'
    end
    context 'with CR line endings' do
      it_behaves_like 'successful upload', 'cr_line_endings_users.csv'
    end
    context "when the isn't csv uploaded" do
      before { post :import }
      it_behaves_like 'failure'
    end
  end
end
