# frozen_string_literal: true

require 'sinatra/base'

module Pruny
  class App < Sinatra::Base
    include Configurable
    use Rollbar::Middleware::Sinatra

    configure do
      Rollbar.configure do |rollbar|
        rollbar.access_token = config.rollbar_access_token
        rollbar.enabled = false if RACK_ENV == 'test'
      end
    end

    get '/tree/:name' do
      config.controller.handle_request(params, self)
    end
  end
end
