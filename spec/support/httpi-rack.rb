require 'httpi'
require 'httpi/adapter/base'
require 'httpi/response'

module HTTPI
  module Adapter
    class Rack < Base
      register :rack, :deps => %w(rack/mock)

      class << self
        attr_accessor :mounted_apps
      end

      self.mounted_apps = {}

      def self.mount(host, application)
        self.mounted_apps[host] = application
      end

      def initialize(request)
        @request = request
        @app     = self.class.mounted_apps[@request.url.host]
        @client  = ::Rack::MockRequest.new(@app)
      end

      def request(method)
        if %w{get post head put delete}.include?(method.to_s)
          env = {}
          @request.headers.each do |header, value|
            env["HTTP_#{header.gsub('-', '_').upcase}"] = value
          end

          response = @client.request(method.to_s.upcase, @request.url.to_s,
                { :fatal => true, :input => @request.body.to_s }.merge(env))

          Response.new(response.status, response.headers, response.body)
        else
          raise "Method `#{method.to_s}' is not supported by HTTPI rack adapter"
        end
      end
    end
  end
end
