# frozen_string_literal: true

require 'ldclient-rb'
require 'open_feature/sdk'

module LaunchDarkly
  module OpenFeature
    module Impl
      #
      # Translates LaunchDarkly data source status changes into OpenFeature provider events.
      #
      class DataSourceStatusListener
        #
        # @param provider [LaunchDarkly::OpenFeature::Provider]
        #
        def initialize(provider)
          @provider = provider
        end

        #
        # @param status [LaunchDarkly::Interfaces::DataSource::Status]
        #
        # @return [void]
        #
        def update(status)
          case status.state
          when ::LaunchDarkly::Interfaces::DataSource::Status::VALID
            @provider.emit_event(::OpenFeature::SDK::ProviderEvent::PROVIDER_READY)
          when ::LaunchDarkly::Interfaces::DataSource::Status::INTERRUPTED
            @provider.emit_event(
              ::OpenFeature::SDK::ProviderEvent::PROVIDER_STALE,
              message: message(status, "the data source has been interrupted")
            )
          when ::LaunchDarkly::Interfaces::DataSource::Status::OFF
            @provider.emit_event(
              ::OpenFeature::SDK::ProviderEvent::PROVIDER_ERROR,
              error_code: ::OpenFeature::SDK::Provider::ErrorCode::GENERAL,
              message: message(status, "the data source has been permanently shut down")
            )
          end
        end

        #
        # @param status [LaunchDarkly::Interfaces::DataSource::Status]
        # @param fallback [String]
        #
        # @return [String]
        #
        private def message(status, fallback)
          error = status.last_error
          return fallback if error.nil?

          "#{fallback}: #{error.kind} #{error.status_code} #{error.message}".strip
        end
      end

      #
      # Translates LaunchDarkly flag change events into OpenFeature configuration changed events.
      #
      class FlagChangeListener
        #
        # @param provider [LaunchDarkly::OpenFeature::Provider]
        #
        def initialize(provider)
          @provider = provider
        end

        #
        # @param flag_change [LaunchDarkly::Interfaces::FlagChange]
        #
        # @return [void]
        #
        def update(flag_change)
          @provider.emit_event(
            ::OpenFeature::SDK::ProviderEvent::PROVIDER_CONFIGURATION_CHANGED,
            flags_changed: [flag_change.key]
          )
        end
      end
    end
  end
end
