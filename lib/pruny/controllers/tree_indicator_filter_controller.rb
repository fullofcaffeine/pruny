# frozen_string_literal: true

module Pruny
  module Controllers
    class TreeIndicatorFilterController
      GENERAL_ERROR_CLIENT_MESSAGE = 'Woopsie! The server got confused. We have been notified.'

      def initialize(tree_service, error_reporter)
        @tree_service = tree_service
        @error_reporter = error_reporter
      end

      def handle_request(params, app)
        app.content_type :json

        tree_name = params['name']
        ids = params['indicator_ids'].map(&:to_i)

        source_structure = @tree_service.get(tree_name)
        tree = Models::Tree.from_json(source_structure)

        tree
          .filter('indicators', 'id', ids.map(&:to_i))
          .map(&:as_json)
          .flatten
          .to_json
      rescue Pruny::Services::TreeServiceError => tree_service_error
        @error_reporter.error(tree_service_error)
        app.response.status = tree_service_error.status
        {error: tree_service_error.message_for_client}.to_json
      rescue StandardError => general_error
        @error_reporter.error(general_error)
        app.response.status = 500
        {error: GENERAL_ERROR_CLIENT_MESSAGE}.to_json
      end
    end
  end
end
