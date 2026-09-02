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
          @lock = Mutex.new
          @last_event = nil
        end

        #
        # @param status [LaunchDarkly::Interfaces::DataSource::Status]
        #
        # @return [void]
        #
        def update(status)
          case status.state
          when ::LaunchDarkly::Interfaces::DataSource::Status::VALID
            emit_once(::OpenFeature::SDK::ProviderEvent::PROVIDER_READY)
          when ::LaunchDarkly::Interfaces::DataSource::Status::INTERRUPTED
            emit_once(
              ::OpenFeature::SDK::ProviderEvent::PROVIDER_STALE,
              message: message(status, "the data source has been interrupted")
            )
          when ::LaunchDarkly::Interfaces::DataSource::Status::OFF
            emit_once(
              ::OpenFeature::SDK::ProviderEvent::PROVIDER_ERROR,
              error_code: ::OpenFeature::SDK::Provider::ErrorCode::GENERAL,
              message: message(status, "the data source has been permanently shut down")
            )
          end
        end

        #
        # Emit an event only when it reports a different provider status than the last one emitted. Several data
        # source states can map to the same provider status, and a repeated status is not a change the application
        # can act on.
        #
        # @param event [Symbol]
        # @param details [Hash]
        #
        # @return [void]
        #
        private def emit_once(event, **details)
          @lock.synchronize do
            return if @last_event == event

            @last_event = event
          end

          @provider.emit_event(event, **details)
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
      # Reports the first data source state which decides the outcome of the client's initial connection attempt.
      #
      class DataSourceOutcomeListener
        #
        # @param outcome [Queue]
        #
        def initialize(outcome)
          @outcome = outcome
        end

        #
        # @param status [LaunchDarkly::Interfaces::DataSource::Status]
        #
        # @return [void]
        #
        def update(status)
          case status.state
          when ::LaunchDarkly::Interfaces::DataSource::Status::VALID,
            ::LaunchDarkly::Interfaces::DataSource::Status::OFF
            @outcome.push(status.state)
          end
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
