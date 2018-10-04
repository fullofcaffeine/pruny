# frozen_string_literal: true

require 'spec_helper'

describe Pruny::Services::TreeService do
  let(:tree_service) { Pruny::Services::TreeService.new('http://tree.service.test/tree') }
  describe '#get' do
    let(:expected_parsed_json) { {'some' => 'awesome tree'} }

    describe 'when external service is succesfull' do
      before do
        stub_request(:get, 'http://tree.service.test/tree/input')
          .to_return(body: '{"some": "awesome tree"}')
      end

      it 'returns the parsed tree json' do
        assert_equal(expected_parsed_json, tree_service.get('input'))
      end
    end

    describe 'on error' do
      describe 'when one of the subsequent requests are succesful' do
        before do
          stub_request(:get, 'http://tree.service.test/tree/input')
            .to_return(body: 'Derp Error', status: 500)
            .then.to_return(body: 'Derp Error', status: 500)
            .then.to_return(body: 'Derp Error', status: 500)
            .then.to_return(body: '{"some": "awesome tree"}')
        end
        it 'retries up to 4 times until it gets the parsed tree json' do
          assert_equal(expected_parsed_json, tree_service.get('input'))
        end
      end

      describe 'when all retries fail' do
        before do
          stub_request(:get, 'http://tree.service.test/tree/input')
            .to_return(body: 'Derp Error', status: 500)
            .then.to_return(body: 'Derp Error', status: 500)
            .then.to_return(body: 'Derp Error', status: 500)
            .then.to_return(body: 'Derp Error', status: 500)
        end

        it 'raises a TreeServiceError' do
          e = assert_raises Pruny::Services::TreeServiceError do
            tree_service.get('input')
          end
          assert_equal(500, e.status)
        end
      end

      describe 'when upstream tree does not exist' do
        before do
          stub_request(:get, 'http://tree.service.test/tree/wut')
            .to_return(body: {'error': "Can't find that tree"}.to_json, status: 404)
        end

        it 'raises a TreeNotFoundError' do
          e = assert_raises Pruny::Services::TreeNotFoundError do
            tree_service.get('wut')
          end
          assert_equal(404, e.status)
        end
      end
    end
  end
end
