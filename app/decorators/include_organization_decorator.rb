require 'decorators/include_decorator'

module VCAP::CloudController
  class IncludeOrganizationDecorator < IncludeDecorator
    class << self
      def include_name
        'org'
      end

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

  IncludeDecoratorRegistry.register(IncludeOrganizationDecorator)
end
