# frozen_string_literal: true
require 'spec_helper'

shared_examples_for 'successful request' do |template|
  it { is_expected.to respond_with(:success) }
  it { is_expected.to render_template(template) }
  it { is_expected.not_to set_flash }
end

shared_examples_for 'redirected request' do
  it { expect(response).to be_redirect }
  it { is_expected.to set_flash }
end
