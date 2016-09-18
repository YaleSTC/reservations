# frozen_string_literal: true
require 'spec_helper.rb'

def expect_email(email)
  delivered = ActionMailer::Base.deliveries.last
  expected =  email.deliver_now

  expect(delivered.multipart?).to eq(expected.multipart?)
  expect(delivered.headers.except('Message-Id')).to\
    eq(expected.headers.except('Message-Id'))
end
