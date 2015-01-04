require 'spec_helper.rb'

def expect_email(email)
  delivered = ActionMailer::Base.deliveries.last
  expected =  email.deliver

  expect(delivered.multipart?).to eq(expected.multipart?)
  expect(delivered.headers.except('Message-Id')).to\
    eq(expected.headers.except('Message-Id'))
end
