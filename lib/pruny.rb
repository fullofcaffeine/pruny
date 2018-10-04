# frozen_string_literal: true

RACK_ENV = ENV['RACK_ENV'] ||= 'development' unless defined?(RACK_ENV)

require 'yaml'
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, RACK_ENV)

require 'rollbar/middleware/sinatra'

require_relative 'pruny/models/tree/concerns/filterable'
require_relative 'pruny/models/tree/concerns/json_convertible'
require_relative 'pruny/models/tree/tree_node'
require_relative 'pruny/models/tree'

require_relative 'pruny/services/tree_service'

require_relative 'pruny/controllers/tree_indicator_filter_controller'

require_relative 'pruny/configuration'
require_relative 'pruny/app'

module Pruny
end
