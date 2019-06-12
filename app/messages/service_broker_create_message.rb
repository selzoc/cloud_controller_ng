require 'messages/base_message'
require 'utils/hash_utils'

module VCAP::CloudController
  class ServiceBrokerCreateMessage < BaseMessage
    register_allowed_keys [:name, :url, :credentials]
    ALLOWED_CREDENTIAL_TYPES = ['basic'].freeze

    validates_with NoAdditionalKeysValidator

    validates :name, string: true
    validates :url, string: true
    validates :credentials, hash: true
    validates :credentials_data, hash: true
    validates_inclusion_of :credentials_type, in: ALLOWED_CREDENTIAL_TYPES,
      message: "credentials.type must be one of #{ALLOWED_CREDENTIAL_TYPES}"

    validate :validate_credentials_data
    validate :validate_url
    validate :validate_name

    def credentials_type
      HashUtils.dig(credentials, :type)
    end

    def credentials_data
      HashUtils.dig(credentials, :data)
    end

    def basic_credentials_data
      @basic_credentials_data ||= BasicCredentialsMessage.new(credentials_data)
    end

    def validate_credentials_data
      unless basic_credentials_data.valid?
        errors.add(
          :credentials_data,
          "Field(s) #{basic_credentials_data.errors.keys.map(&:to_s)} must be valid: #{basic_credentials_data.errors.full_messages}"
        )
      end
    end

    def validate_url
      if URI::DEFAULT_PARSER.make_regexp(['https', 'http']).match?(url.to_s)
        errors.add(:url, 'url must not contain credentials') if URI(url).user
      else
        errors.add(:url, 'must be a valid url')
      end
    end

    def validate_name
      if name == ''
        errors.add(:name, 'must not be empty string')
      end
    end

    class BasicCredentialsMessage < BaseMessage
      register_allowed_keys [:username, :password]

      validates_with NoAdditionalKeysValidator

      validates :username, string: true
      validates :password, string: true
    end
  end
end
