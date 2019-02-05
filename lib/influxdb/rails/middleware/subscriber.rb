require "influxdb/rails/logger"

module InfluxDB
  module Rails
    module Middleware
      # Subscriber acts as base class for different *Subscriber classes,
      # which are intended as ActiveSupport::Notifications.subscribe
      # consumers.
      class Subscriber
        include InfluxDB::Rails::Logger

        attr_reader :configuration

        def initialize(configuration, series_name)
          @configuration = configuration
          @series_name = series_name
        end

        def call(*)
          raise NotImplementedError, "must be implemented in subclass"
        end

        private

        attr_reader :series_name

        def timestamp(time)
          InfluxDB.convert_timestamp(time.utc, client.time_precision)
        end

        def client
          @client = configuration.client
        end

        def tags(tags)
          result = tags.merge(InfluxDB::Rails.current.tags)
          result = configuration.tags_middleware.call(result)
          result.reject! do |_, value|
            value.nil? || value == ""
          end
          result
        end

        def enabled?
          configuration.instrumentation_enabled? &&
            !configuration.ignore_current_environment?
        end

        def location
          current = InfluxDB::Rails.current
          [
            current.controller,
            current.action,
          ].reject(&:blank?).join("#")
        end
      end
    end
  end
end
