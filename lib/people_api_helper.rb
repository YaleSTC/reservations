# frozen_string_literal: true

require 'json'

# Helper class to handle requests to a web-service-based user profile API and
# return profile data
class PeopleAPIHelper
  # Allows for the calling of .search on the base class
  def self.search(**params)
    new(**params).search
  end

  # Initialize a new PeopleAPIHelper and generates the request object for the
  # web service
  #
  # @param login [String] the login value to query for
  def initialize(login:)
    @login = login
    @req = generate_request
  end

  # Execute an API query for profile data, returning a hash with the results if
  # they are found
  #
  # @return [Hash] the profile data returned by the API service
  def search
    send_request
    parse_response
  end

  private

  ATTRS = { cas_login: 'LOGIN', first_name: 'FNAME', last_name: 'LNAME',
            email: 'EMAIL', affiliation: 'AFF' }.freeze

  attr_reader :login, :req, :response

  def generate_request
    req = req_klass.new(uri)
    req.basic_auth api_env('USERNAME'), api_env('PASSWORD')
    req
  end

  def req_klass
    klass_name = api_env('METHOD').capitalize
    Net::HTTP.const_get(klass_name)
  end

  def send_request
    @raw ||= Net::HTTP.start(uri.host, uri.port, use_ssl: ssl?) do |http|
      http.request(req)
    end
    @response ||= JSON.parse(@raw.body)
  end

  def parse_response
    {}.tap do |out|
      ATTRS.each { |(attr, str)| out[attr] = extract_data(str) }
      out[:username] = ENV['CAS_AUTH'].present? ? out[:cas_login] : out[:email]
    end
  end

  def extract_data(attr)
    response.dig(*api_env(attr).split(','))
  end

  def ssl?
    !(uri.to_s =~ /https/).nil?
  end

  def uri
    @uri ||= URI(full_url)
  end

  # The full request URL - either sets up a single query param with a '?' if
  # there aren't any in the string or appends using '&' if the URL already
  # contains a query param
  def full_url
    char = (api_env('URL') =~ /\?/).nil? ? '?' : '&'
    api_env('URL') + "#{char}#{api_env('PARAM')}=#{login}"
  end

  def api_env(str)
    ENV["RES_PEOPLE_API_#{str}"]
  end
end
