# frozen_string_literal: true

module Pruny
  module Services
    TREE_SERVICE_CLIENT_ERROR_MESSAGE = 'The upstream service did not behave well :(. We have been notified.'
    TREE_NOT_FOUND_CLIENT_ERROR_MESSAGE = 'Tree not found.'

    # If more services are added, add a base exception class with a common message.
    class TreeServiceError < StandardError
      attr_reader :status

      def initialize(status, error_message, response_body)
        @status = status
        @error_message = error_message
        @response_body = response_body
      end

      def message
        "status: \"#{@status}\", error: \"#{@error_message}\", body: \"#{@response_body.inspect}\""
      end

      def message_for_client
        TREE_SERVICE_CLIENT_ERROR_MESSAGE
      end
    end

    class TreeNotFoundError < TreeServiceError
      def initialize(response_body)
        super(
          404,
          'Tree not found on the upstream service',
          response_body
        )
      end

      def message_for_client
        TREE_NOT_FOUND_CLIENT_ERROR_MESSAGE
      end
    end

    class TreeService
      def initialize(base_url)
        @conn = Faraday.new(url: base_url) do |c|
          c.use Faraday::Response::RaiseError
          c.request :retry, max: 4, retry_statuses: [500], retry_block: method(:retry_sentinel)
          c.adapter Faraday.default_adapter
        end
      end

      def get(path)
        response = @conn.get(path)
        Oj.load(response.body)
      rescue Faraday::Error::ResourceNotFound => e
        raise TreeNotFoundError, e.response[:body]
      end

      private

      def retry_sentinel(env, _, retries, _)
        return unless retries.zero?

        raise TreeServiceError.new(
          env.status,
          env.reason_phrase,
          env.body
        )
      end
    end
  end
end
