# frozen_string_literal: true

module Pruny
  module Configuration
    # Plain ruby configuration object. I don't quite like the way Sinatra handles
    # configuration (with `set` and `settings`), so I usually roll my own.
    #
    # Include the Configurable module and a `config` method will be available.
    # We have only one controller for now, and the app, being a microservice
    # will probably only have this controller, hence we name this conf. accessor
    # method `controller`. 'Nuff for now and easy to change / add more if needed.
    def controller
      @controller ||= Controllers::TreeIndicatorFilterController.new(tree_service, Rollbar)
    end

    def rollbar_access_token
      ENV['ROLLBAR_ACCESS_TOKEN']
    end

    def tree_service_url
      settings['tree_service_url']
    end

    def tree_service
      @tree_service ||= Services::TreeService.new(tree_service_url)
    end

    private

    def settings
      @settings ||= YAML.load_file(
        File.join(File.dirname(__FILE__), '..', '..', 'settings.yml')
      )[RACK_ENV]
    end
  end

  module Configurable
    def self.included(base)
      base.extend self
    end

    def config
      @config ||= Class.new do
        extend Configuration
      end
    end
  end
end
