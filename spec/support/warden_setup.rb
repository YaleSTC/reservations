# Warden test mode for authentication
Warden.test_mode!

module InjectSession
  def inject_session(hash)
    Warden.on_next_request do |proxy|
      hash.each do |key, value|
        proxy.raw_session[key] = value
      end
    end
  end
end