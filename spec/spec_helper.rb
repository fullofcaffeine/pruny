# frozen_string_literal: true

RACK_ENV = 'test'

require_relative '../lib/pruny'

require 'minitest/autorun'
require 'webmock/minitest'
require 'mocha/minitest'
require 'rack/test'
