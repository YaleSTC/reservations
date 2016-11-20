# frozen_string_literal: true

require 'net/ldap'

class LDAPHelper
  def self.search(**params)
    new(**params).search
  end

  def initialize(login:)
    @ldap = Net::LDAP.new(conn_settings)
    @user_login = login
  end

  def search
    user_hash
  end

  private

  ATTRS = %i(login email first_name last_name nickname).freeze
  attr_reader :user_login, :ldap

  def user_hash # rubocop:disable Metrics/AbcSize
    return {} if result.empty?
    {}.tap do |out|
      out[:first_name] = result[secrets.ldap_first_name.to_sym][0]
      out[:last_name] = result[secrets.ldap_last_name.to_sym][0]
      out[:nickname] = result[secrets.ldap_nickname.to_sym][0]
      out[:email] = result[secrets.ldap_email.to_sym][0]

      # deal with affiliation
      out[:affiliation] = aff_params.map { |param| result[param.to_sym][0] }
                                    .select { |s| s && !s.empty? }.join(' ')

      # define username based on authentication method
      out[:username] = if ENV['CAS_AUTH']
                         result[secrets.ldap_login.to_sym][0]
                       else
                         out[:email]
                       end
    end
  end

  def result
    @result ||= ldap.search(base: secrets.ldap_base,
                            filter: filter,
                            attributes: attrs).first
  end

  def filter
    @filter ||= Net::LDAP::Filter.eq(filter_param, user_login)
  end

  def filter_param
    ENV['CAS_AUTH'] ? secrets.ldap_login : secrets.ldap_email
  end

  def attrs
    ldap_attrs = ATTRS.map { |a| "ldap_#{a}".to_sym }
    @attrs ||= affilation_params + ldap_attrs.map { |a| secrets.send(a) }
  end

  def affiliation_params
    @aff_params ||= secrets.ldap_affiliation.split(',')
    @aff_params ||= []
  end

  def secrets
    Rails.application.secrets
  end

  def conn_settings
    { host: secrets.ldap_host, port: secrets.ldap_port }
  end
end
