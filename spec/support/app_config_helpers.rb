# frozen_string_literal: true
module AppConfigHelpers
  def mock_app_config(**attrs)
    ac = spy('AppConfig', require_phone: false, **attrs)
    allow(AppConfig).to receive(:first).and_return(ac)
    ac
  end
end
