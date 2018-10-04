# frozen_string_literal: true

require 'spec_helper'

describe Pruny::Controllers::TreeIndicatorFilterController do
  describe '#handle_request' do
    let(:controller) do
      Pruny::Controllers::TreeIndicatorFilterController.new(tree_service_mock, error_reporter_mock)
    end

    let(:error_reporter_mock) { mock('error_reporter') }
    let(:app_mock) { mock('app') }
    let(:response_mock) { mock('response') }
    let(:tree_service_mock) { mock('tree_service') }
    let(:params) { {'indicator_ids' => %w[1 2], 'name' => 'input'} }
    let(:source_structure) do
      [
        {
          'id' => 1,
          'indicators' => [
            {'id' => 1, 'name' => 'such awesome'},
            {'id' => 2, 'name' => 'such awesome2'}
          ]
        }
      ]
    end

    before do
      app_mock.expects(:content_type).with(:json)
      app_mock.stubs(:response).returns(response_mock)
      tree_service_mock.stubs(:get).with('input').returns(source_structure)
    end

    describe 'succesfull request' do
      specify do
        output = controller.handle_request(params, app_mock)
        assert_equal(source_structure.to_json, output)
      end
    end

    describe 'on error' do
      before do
        tree_service_mock.stubs(:get).then.raises(exception)
        error_reporter_mock.expects(:error).with(exception)
        response_mock.expects(:status=).with(expected_status)
      end

      describe 'on TreeServiceError' do
        let(:expected_status) { 500 }
        let(:exception) { Pruny::Services::TreeServiceError.new(500, 'very, very bad', 'too sexy') }

        specify do
          output = controller.handle_request(params, app_mock)
          assert_equal(
            output,
            {error: Pruny::Services::TREE_SERVICE_CLIENT_ERROR_MESSAGE}.to_json
          )
        end
      end

      # Out of completeness
      describe 'on TreeNotFoundError' do
        let(:expected_status) { 404 }
        let(:exception) { Pruny::Services::TreeNotFoundError.new('not found body') }

        specify do
          output = controller.handle_request(params, app_mock)
          assert_equal(
            output,
            {error: Pruny::Services::TREE_NOT_FOUND_CLIENT_ERROR_MESSAGE}.to_json
          )
        end
      end

      # Tests that the controller catches any other edge-case exceptions that we might not
      # have thought about, sending to Rollbar so we can investigate, instead of showing it
      # naked to the end user.
      describe 'on any other general error (inherited from StandardError)' do
        let(:expected_status) { 500 }
        let(:exception) { StandardError.new('woopsie') }

        specify do
          output = controller.handle_request(params, app_mock)
          assert_equal(
            output,
            {error: Pruny::Controllers::TreeIndicatorFilterController::GENERAL_ERROR_CLIENT_MESSAGE}.to_json
          )
        end
      end
    end
  end
end
