# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require "rspec/rails"
require "pry"
require "savon"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  require 'rspec/expectations'
  config.include RSpec::Matchers

  config.mock_with :rspec
  config.before(:all) do
    WashOut::Engine.snakecase_input = false
    WashOut::Engine.camelize_wsdl   = false
    WashOut::Engine.namespace       = false
  end
end

HTTPI.logger = Logger.new(open("/dev/null", 'w'))
HTTPI.adapter = :rack

HTTPI::Adapter::Rack.mount 'app', Dummy::Application
Dummy::Application.routes.draw do
  wash_out :api
end

def mock_controller(&block)
  Object.send :remove_const, :ApiController if defined?(ApiController)
  Object.send :const_set, :ApiController, Class.new(ApplicationController) {
    include WashOut::SOAP

    class_exec &block if block
  }

  if Rails.application.routes.routes.is_a?(Array)
    Rails.application.routes.named_routes['api_wsdl'].app.
      instance_variable_get("@controllers")['api'].try(:'clear!')
  else
    Rails.application.routes.routes.named_routes['api_wsdl'].app.
      instance_variable_get("@controllers")['api'].try(:'clear!')
  end
end
