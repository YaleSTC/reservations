# frozen_string_literal: true
require 'active_support/testing/time_helpers'

if defined? FactoryGirl
  FactoryGirl::SyntaxRunner.send(:include, ActiveSupport::Testing::TimeHelpers)
end
