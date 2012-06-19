class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "[#{message.to}] #{message.subject}"
<<<<<<< HEAD
    message.to = "stc_mail_testing@googlegroupc.com"
=======
    message.to = "stc_mail_testing@googlegroups.com"
>>>>>>> rails3_errors
  end
end