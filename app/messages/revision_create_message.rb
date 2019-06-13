require 'messages/metadata_base_message'

module VCAP::CloudController
  class RevisionCreateMessage < MetadataBaseMessage
    register_allowed_keys [
      :app_guid,
      :droplet_guid,
      :environment_variables,
      :description,
      :commands_by_process_type
    ]

    validates_with NoAdditionalKeysValidator
  end
end
