require 'spec_helper'
require 'messages/apps_list_message'

module VCAP::CloudController
  RSpec.describe AppListFetcher do
    let!(:stack) { Stack.make }
    let(:space) { Space.make }
    let!(:app) { AppModel.make(space_guid: space.guid, name: 'app') }
    let!(:sad_app) { AppModel.make(space_guid: space.guid) }
    let(:org) { space.organization }
    let(:fetcher) { AppListFetcher.new }
    let(:space_guids) { [space.guid] }
    let(:pagination_options) { PaginationOptions.new({}) }
    let(:filters) { {} }
    let(:message) { AppsListMessage.from_params(filters) }
    let!(:lifecycle_data_for_app) {
      BuildpackLifecycleDataModel.make(
        app: app,
        stack: stack.name,
        buildpacks: [Buildpack.make.name]
      )
    }
    let!(:lifecycle_data_for_sad_app) {
      BuildpackLifecycleDataModel.make(app: sad_app, stack: nil)
    }

    context '#fetch_all' do
      it 'eager loads the specified resources for all apps' do
        results = fetcher.fetch_all(message, eager_loaded_associations: [:labels, { buildpack_lifecycle_data: :buildpack_lifecycle_buildpacks }]).all

        expect(results.first.buildpack_lifecycle_data.associations.key?(:buildpack_lifecycle_buildpacks)).to be true
        expect(results.first.associations.key?(:buildpack_lifecycle_data)).to be true
        expect(results.first.associations.key?(:labels)).to be true
        expect(results.first.associations.key?(:annotations)).to be false
      end

      it 'includes all the apps' do
        app = AppModel.make
        expect(fetcher.fetch_all(message).all).to include(app, sad_app)
      end
    end

    describe '#fetch' do
      let(:apps) { fetcher.fetch(message, space_guids) }

      it 'eager loads the specified resources for all apps' do
        results = fetcher.fetch(message, space_guids, eager_loaded_associations: [:labels, { buildpack_lifecycle_data: :buildpack_lifecycle_buildpacks }]).all

        expect(results.first.buildpack_lifecycle_data.associations.key?(:buildpack_lifecycle_buildpacks)).to be true
        expect(results.first.associations.key?(:buildpack_lifecycle_data)).to be true
        expect(results.first.associations.key?(:labels)).to be true
        expect(results.first.associations.key?(:annotations)).to be false
      end

      context 'when no filters are specified' do
        it 'returns all of the desired apps' do
          expect(apps.all).to contain_exactly(app, sad_app)
        end
      end

      context 'when the app names are provided' do
        let(:filters) { { names: [app.name] } }

        it 'returns all of the desired apps' do
          expect(apps.all).to contain_exactly(app)
        end
      end

      context 'when the app space_guids are provided' do
        let(:filters) { { space_guids: [space.guid] } }
        let(:sad_app) { AppModel.make }

        it 'returns all of the desired apps' do
          expect(apps.all).to contain_exactly(app)
        end
      end

      context 'when the organization guids are provided' do
        let(:filters) { { organization_guids: [org.guid] } }
        let(:sad_org) { Organization.make }
        let(:sad_space) { Space.make(organization_guid: sad_org.guid) }
        let(:sad_app) { AppModel.make(space_guid: sad_space.guid) }
        let(:space_guids) { [space.guid, sad_space.guid] }

        it 'returns all of the desired apps' do
          expect(apps.all).to contain_exactly(app)
        end
      end

      context 'when a stack is provided' do
        let(:filters) { { stacks: [lifecycle_data_for_app.stack] } }

        it 'returns all of the desired apps' do
          expect(apps.all).to contain_exactly(app)
        end
      end

      context 'when an empty stack is provided' do
        let(:filters) { { stacks: [''] } }

        it 'returns all of the desired apps' do
          expect(apps.all).to contain_exactly(sad_app)
        end
      end

      context 'when the app guids are provided' do
        let(:filters) { { guids: [app.guid] } }

        it 'returns all of the desired apps' do
          expect(apps.all).to contain_exactly(app)
        end
      end

      context 'when a label_selector is provided' do
        let(:filters) { { 'label_selector' => 'dog in (chihuahua,scooby-doo)' } }
        let!(:app_label) do
          VCAP::CloudController::AppLabelModel.make(resource_guid: app.guid, key_name: 'dog', value: 'scooby-doo')
        end
        let!(:sad_app_label) do
          VCAP::CloudController::AppLabelModel.make(resource_guid: sad_app.guid, key_name: 'dog', value: 'poodle')
        end

        it 'returns all of the desired apps' do
          expect(apps.all).to contain_exactly(app)
        end

        context 'and other filters are present' do
          let!(:happiest_app) { AppModel.make(space_guid: space.guid, name: 'bob') }
          let!(:happiest_app_label) do
            VCAP::CloudController::AppLabelModel.make(resource_guid: happiest_app.guid, key_name: 'dog', value: 'scooby-doo')
          end
          let(:filters) { { 'names' => 'bob', 'label_selector' => 'dog in (chihuahua,scooby-doo)' } }

          it 'returns the desired app' do
            expect(apps.all).to contain_exactly(happiest_app)
          end
        end
      end

      context 'when a lifecycle_type is provided' do
        let!(:docker_app) { AppModel.make(name: 'docker-app', space_guid: space.guid) }

        before do
          docker_app.buildpack_lifecycle_data = nil
          docker_app.save
        end

        context 'of type buildpack' do
          let(:filters) { { lifecycle_type: 'buildpack' } }

          it 'returns all of the buildpack apps' do
            expect(apps.all).to contain_exactly(app, sad_app)
          end
        end

        context 'of type docker' do
          let(:filters) { { lifecycle_type: 'docker' } }

          it 'returns all of the docker apps' do
            expect(apps.all).to contain_exactly(docker_app)
          end
        end
      end
    end
  end
end
