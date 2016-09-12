# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/user_mock.rb')

module ControllerHelpers
  def mock_user_sign_in(user = UserMock.new(traits: [:findable]))
    pass_app_setup_check
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    # necessary for permissions to work
    allow(ApplicationController).to receive(:current_user).and_return(user)
    allow(Ability).to receive(:new).and_return(Ability.new(user))
    allow_any_instance_of(described_class).to \
      receive(:current_user).and_return(user)
  end

  def pass_app_setup_check
    allow(AppConfig).to receive(:first).and_return(true) unless AppConfig.first
    allow(User).to receive(:count).and_return(1) unless User.first
  end
end
