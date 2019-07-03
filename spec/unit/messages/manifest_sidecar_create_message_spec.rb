require 'spec_helper'
require 'messages/manifest_sidecar_create_message'

module VCAP::CloudController
  RSpec.describe ManifestSidecarCreateMessage do
    let(:body) do
      {
        name: 'my sidecar',
        command: 'bundle exec rackup',
        process_types: ['web', 'worker'],
        memory: 300
      }
    end

    describe 'validations' do
      it 'validates happy path' do
        message = ManifestSidecarCreateMessage.new(body)
        expect(message).to be_valid
      end

      it 'validates that there are not excess fields' do
        body['bogus'] = 'field'
        message = ManifestSidecarCreateMessage.new(body)

        expect(message).to_not be_valid
        expect(message.errors.full_messages).to include("Unknown field(s): 'bogus'")
      end

      it 'validates name is present' do
        body[:name] = ''
        message = ManifestSidecarCreateMessage.new(body)

        expect(message).to_not be_valid
        expect(message.errors.full_messages).to include("Name can't be blank")
      end

      it 'validates command is present' do
        body[:command] = ''
        message = ManifestSidecarCreateMessage.new(body)

        expect(message).to_not be_valid
        expect(message.errors.full_messages).to include("Command can't be blank")
      end

      it 'validates that there is at least one process_type' do
        body[:process_types] = []
        message = ManifestSidecarCreateMessage.new(body)

        expect(message).to_not be_valid
        expect(message.errors.full_messages).to include('Process types must have at least 1 process_type')
      end

      it 'validates that memory is a positive integer' do
        body[:memory] = 'totes not a number'
        message = ManifestSidecarCreateMessage.new(body)

        expect(message).to_not be_valid
        expect(message.errors.full_messages).to include('Memory is not a number')
      end
    end
  end
end
