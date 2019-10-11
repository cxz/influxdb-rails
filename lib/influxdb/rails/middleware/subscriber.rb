module InfluxDB
  module Rails
    module Middleware
      # Subscriber acts as base class for different *Subscriber classes,
      # which are intended as ActiveSupport::Notifications.subscribe
      # consumers.
      class Subscriber
        attr_reader :configuration
        attr_reader :hook_name

        def initialize(configuration, hook_name)
          @configuration = configuration
          @hook_name = hook_name
        end

        def call(*)
          raise NotImplementedError, "must be implemented in subclass"
        end

        private

        def timestamp(time)
          InfluxDB.convert_timestamp(time.utc, client.time_precision)
        end

        def client
          @client = configuration.client
        end

        def tags(tags)
          result = configuration.tags_middleware.call(tags.merge(default_tags))
          result.reject! do |_, value|
            value.nil? || value == ""
          end
          result
        end

        def default_tags
          {
            server:   Socket.gethostname,
            app_name: configuration.application_name,
          }.merge(InfluxDB::Rails.current.tags)
        end

        def enabled?
          configuration.instrumentation_enabled? &&
            !configuration.ignore_current_environment? &&
            !configuration.ignored_hooks.include?(hook_name)
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
