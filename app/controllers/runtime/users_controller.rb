module VCAP::CloudController
  class UsersController < RestController::ModelController
    define_attributes do
      attribute :guid, String
      attribute :admin, Message::Boolean, :default => false
      to_many   :spaces
      to_many   :organizations
      to_many   :managed_organizations
      to_many   :billing_managed_organizations
      to_many   :audited_organizations
      to_many   :managed_spaces
      to_many   :audited_spaces
      to_one    :default_space, :optional_in => [:create]
    end

    query_parameters :space_guid, :organization_guid,
      :managed_organization_guid,
      :billing_managed_organization_guid,
      :audited_organization_guid,
      :managed_space_guid,
      :audited_space_guid

    def self.translate_validation_exception(e, attributes)
      guid_errors = e.errors.on(:guid)
      if guid_errors && guid_errors.include?(:unique)
        Errors::ApiError.new_from_details("UaaIdTaken", attributes["guid"])
      else
        Errors::ApiError.new_from_details("UserInvalid", e.errors.full_messages)
      end
    end

    def read(guid)
      # only admins should have unfettered access to all users
      # UserAccess allows all to read so org and space user lists show all users in those lists
      raise Errors::ApiError.new_from_details("NotAuthorized") unless roles.admin?
      super
    end

    def enumerate
      raise Errors::ApiError.new_from_details("NotAuthenticated") unless user
      raise Errors::ApiError.new_from_details("NotAuthorized") unless roles.admin?
      super
    end

    def delete(guid)
      do_delete(find_guid_and_validate_access(:delete, guid))
    end

    define_messages
    define_routes
  end
end
