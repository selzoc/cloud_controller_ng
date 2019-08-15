require 'messages/metadata_base_message'

module VCAP::CloudController
  class UserCreateMessage < MetadataBaseMessage
    register_allowed_keys [:name]

    validates :name, presence: true, length: { maximum: 250 }
    validates :description, length: { maximum: 250 }
  end
end
