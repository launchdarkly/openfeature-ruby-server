# frozen_string_literal: true

require 'ldclient-rb'
require 'open_feature/sdk'

module LaunchDarkly
  module OpenFeature
    class Provider
      attr_reader :metadata

      #
      # @param sdk_key [String]
      # @param config [LaunchDarkly::Config]
      # @param wait_for_seconds [Float]
      #
      def initialize(sdk_key, config, wait_for_seconds = 5)
        @client = LaunchDarkly::LDClient.new(sdk_key, config, wait_for_seconds)

        @context_converter = Impl::EvaluationContextConverter.new(config.logger)
        @details_converter = Impl::ResolutionDetailsConverter.new

        @metadata = ::OpenFeature::SDK::Provider::ProviderMetadata.new(name: "launchdarkly-openfeature-server").freeze
      end

      def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
        resolve_value(:boolean, flag_key, default_value, evaluation_context)
      end

      def fetch_string_value(flag_key:, default_value:, evaluation_context: nil)
        resolve_value(:string, flag_key, default_value, evaluation_context)
      end

      def fetch_number_value(flag_key:, default_value:, evaluation_context: nil)
        resolve_value(:number, flag_key, default_value, evaluation_context)
      end

      def fetch_integer_value(flag_key:, default_value:, evaluation_context: nil)
        resolve_value(:integer, flag_key, default_value, evaluation_context)
      end

      def fetch_float_value(flag_key:, default_value:, evaluation_context: nil)
        resolve_value(:float, flag_key, default_value, evaluation_context)
      end

      def fetch_object_value(flag_key:, default_value:, evaluation_context: nil)
        resolve_value(:object, flag_key, default_value, evaluation_context)
      end

      #
      # @param flag_type [Symbol]
      # @param flag_key [String]
      # @param default_value [any]
      # @param evaluation_context [::OpenFeature::SDK::EvaluationContext, nil]
      #
      # @return [::OpenFeature::SDK::Provider::ResolutionDetails]
      #
      private def resolve_value(flag_type, flag_key, default_value, evaluation_context)
        if evaluation_context.nil?
          return ::OpenFeature::SDK::Provider::ResolutionDetails.new(
            value: default_value,
            reason: ::OpenFeature::SDK::Provider::Reason::ERROR,
            error_code: ::OpenFeature::SDK::Provider::ErrorCode::TARGETING_KEY_MISSING
          )
        end

        ld_context = @context_converter.to_ld_context(evaluation_context)
        evaluation_detail = @client.variation_detail(flag_key, ld_context, default_value)

        if flag_type == :boolean && ![true, false].include?(evaluation_detail.value)
          return mismatched_type_details(default_value)
        elsif flag_type == :string && !evaluation_detail.value.is_a?(String)
          return mismatched_type_details(default_value)
        elsif flag_type == :integer && !evaluation_detail.value.is_a?(Integer)
          return mismatched_type_details(default_value)
        elsif flag_type == :float && !evaluation_detail.value.is_a?(Float)
          return mismatched_type_details(default_value)
        elsif flag_type == :number && !evaluation_detail.value.is_a?(Numeric)
          return mismatched_type_details(default_value)
        elsif flag_type == :object && !evaluation_detail.value.is_a?(Hash) && !evaluation_detail.value.is_a?(Array)
          return mismatched_type_details(default_value)
        end

        @details_converter.to_resolution_details(evaluation_detail)
      end

      #
      # @param default_value [any]
      #
      # @return [::OpenFeature::SDK::Provider::ResolutionDetails]
      #
      private def mismatched_type_details(default_value)
        ::OpenFeature::SDK::Provider::ResolutionDetails.new(
          value: default_value,
          reason: ::OpenFeature::SDK::Provider::Reason::ERROR,
          error_code: ::OpenFeature::SDK::Provider::ErrorCode::TYPE_MISMATCH
        )
      end
    end
  end
end
