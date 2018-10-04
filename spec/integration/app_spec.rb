# frozen_string_literal: true

require 'spec_helper'

describe Pruny::App do
  include Rack::Test::Methods
  let(:external_service_base_url) { 'http://tree.service.test/tree/' }

  def app
    Pruny::App
  end

  describe 'routes' do
    describe '/tree/:name' do
      let(:request_url) { URI.join(external_service_base_url, tree_name) }

      before do
        stub_request(:get, request_url)
          .to_return(body: fixture, status: upstream_status)

        get "/tree/#{tree_name}", query_params
      end

      describe 'existing upstream tree' do
        let(:tree_name) { 'input' }
        let(:expected_output_json) do
          [
            {
              'id' => 2,
              'name' => 'Demographics',
              'sub_themes' => [
                {
                  'id' => 4,
                  'name' => 'Births and Deaths',
                  'categories' => [
                    {
                      'id' => 11,
                      'name' => 'Crude death rate',
                      'unit' => '(deaths per 1000 people)',
                      'indicators' => [
                        {'id' => 1, 'name' => 'total'}
                      ]
                    }
                  ]
                }
              ]
            },
            {
              'id' => 3,
              'name' => 'Jobs',
              'sub_themes' => [
                {
                  'id' => 8,
                  'name' => 'Unemployment',
                  'categories' => [
                    {
                      'id' => 23,
                      'name' => 'Unemployment rate, 15–24 years, usual',
                      'unit' => '(percent of labor force)',
                      'indicators' => [
                        {'id' => 31, 'name' => 'Total'},
                        {'id' => 32, 'name' => 'Female'}
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        end

        let(:fixture) do
          File.read(File.join(File.dirname(__FILE__), '../fixtures/input-tree-fixture.json'))
        end

        describe 'well-formed request' do
          let(:query_params) { 'indicator_ids[]=32&indicator_ids[]=31&indicator_ids[]=1' }

          describe 'upstream service behaves well' do
            let(:upstream_status) { 200 }

            specify do
              assert_equal(expected_output_json, Oj.load(last_response.body))
              assert_equal(200, last_response.status)
            end
          end

          describe 'upstream service fails' do
            let(:upstream_status) { 500 }
            let(:fixture) { 'Internal derper error. Nobody has been notified.' }
            let(:expected_output_json) do
              {'error' => 'The upstream service did not behave well :(. We have been notified.'}
            end

            specify do
              assert_equal(expected_output_json, Oj.load(last_response.body))
            end
          end
        end

        describe 'missing or wrong query parameters' do
          let(:query_params) { nil }
          let(:upstream_status) { 200 }
          let(:expected_output_json) { {'error' => 'Woopsie! The server got confused. We have been notified.'} }

          specify do
            assert_equal(expected_output_json, Oj.load(last_response.body))
          end
        end
      end

      describe 'upstream tree does not exist' do
        let(:tree_name) { 'wut' }
        let(:query_params) { 'indicator_ids[]=32&indicator_ids[]=31&indicator_ids[]=1' }
        let(:upstream_status) { 404 }
        let(:fixture) { {'error': "Can't find that tree"}.to_json }

        let(:expected_output_json) { {'error' => 'Tree not found.'} }

        specify do
          assert_equal(expected_output_json, Oj.load(last_response.body))
        end
      end
    end
  end
end
