module VCAP::CloudController
  class IncludeOrganizationDecorator < IncludeDecorator
    class << self
      def association_name
        'organization'
      end

      def association_class
        Organization
      end

      def presenter
        Presenters::V3::OrganizationPresenter
      end
    end
  end
end
