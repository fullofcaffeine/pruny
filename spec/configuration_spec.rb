# frozen_string_literal: true

require 'spec_helper'

describe Pruny::Configuration do
  class DummyConfigurableClass
    include Pruny::Configurable
  end

  let(:app) { DummyConfigurableClass.new }

  before do
    ENV['ROLLBAR_ACCESS_TOKEN'] = 'very_secret'
  end

  specify do
    assert_instance_of(Pruny::Controllers::TreeIndicatorFilterController, app.config.controller)
    assert_instance_of(Pruny::Services::TreeService, app.config.tree_service)
    assert_equal('very_secret', app.config.rollbar_access_token)
    refute_nil(app.config.tree_service_url)
  end
end
