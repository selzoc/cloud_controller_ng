require 'messages/metadata_base_message'
require 'models/helpers/health_check_types'

module VCAP::CloudController
  class ProcessCreateMessage < MetadataBaseMessage
    register_allowed_keys [:app_guid, :revision_guid, :type]

    validates_with NoAdditionalKeysValidator
  end
end
