require 'spec_helper'
require 'messages/user_create_message'

module VCAP::CloudController
  RSpec.describe UserCreateMessage do
    subject { UserCreateMessage.new(params) }

    describe 'validations' do
      context 'when valid params are given' do
        let(:params) { { guid: 'some-user-guid' } }

        it 'is valid' do
          expect(subject).to be_valid
        end
      end

      context 'when no params are given' do
        let(:params) {}
        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:guid]).to include("can't be blank")
        end
      end

      context 'when unexpected keys are requested' do
        let(:params) do
          {
            unexpected: 'meow',
            guid: 'some-user-guid'
          }
        end

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages[0]).to include("Unknown field(s): 'unexpected'")
        end
      end

      context 'guid' do
        MAX_SUBDOMAIN_LENGTH = DomainCreateMessage::MAXIMUM_DOMAIN_LABEL_LENGTH

        context 'when a valid long multi-subdomain name is given' do
          let(:params) do
            {
              name: (['a'] * 126).join('.'),
            }
          end

          it 'is valid' do
            expect(subject).to be_valid
          end
        end

        context 'when not a string' do
          let(:params) do
            { guid: 5 }
          end

          it 'is not valid' do
            expect(subject).not_to be_valid
            expect(subject.errors[:guid]).to include('must be a string')
          end
        end

        context 'when it is too short' do
          let(:params) { { guid: '' } }

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors[:name]).to include "is too short (minimum is #{MIN_DOMAIN_NAME_LENGTH} characters)"
          end
        end

        context 'when it is too long' do
          let(:params) { { name: 'B' * (MAX_DOMAIN_NAME_LENGTH + 1) } }

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors[:name]).to include "is too long (maximum is #{MAX_DOMAIN_NAME_LENGTH} characters)"
          end
        end

        context 'when it does not contain a .' do
          let(:params) { { name: 'idontlikedots' } }

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors[:name]).to match ['does not comply with RFC 1035 standards', 'must contain at least one "."']
          end
        end

        context 'when the subdomain is too long' do
          let(:params) { { name: 'B' * (MAX_SUBDOMAIN_LENGTH + 1) + '.example.com' } }

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors[:name]).to include 'subdomains must each be at most 63 characters'
          end
        end

        context 'when it contains invalid characters' do
          let(:params) { { name: '_!@#$%^&*().swag' } }

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors[:name]).to include 'must consist of alphanumeric characters and hyphens'
          end
        end

        context 'when it does not conform to RFC 1035' do
          let(:params) { { name: 'B' * (MAX_SUBDOMAIN_LENGTH + 1) + '.example.com' } }

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors[:name]).to include 'does not comply with RFC 1035 standards'
          end
        end
      end
    end
  end
end
