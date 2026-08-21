# frozen_string_literal: true

require 'ldclient-rb'
require 'open_feature/sdk'

module LaunchDarkly
  module OpenFeature
    module Impl
      class ResolutionDetailsConverter
        VARIATION_INDEX_KEY = 'variationIndex'
        IN_EXPERIMENT_KEY = 'inExperiment'
        RULE_INDEX_KEY = 'ruleIndex'
        RULE_ID_KEY = 'ruleId'
        PREREQUISITE_KEY_KEY = 'prerequisiteKey'
        BIG_SEGMENTS_STATUS_KEY = 'bigSegmentsStatus'

        private_constant :VARIATION_INDEX_KEY, :IN_EXPERIMENT_KEY, :RULE_INDEX_KEY, :RULE_ID_KEY,
          :PREREQUISITE_KEY_KEY, :BIG_SEGMENTS_STATUS_KEY

        #
        # @param detail [LaunchDarkly::EvaluationDetail]
        #
        # @return [OpenFeature::SDK::ResolutionDetails]
        #
        def to_resolution_details(detail)
          value = detail.value
          is_default = detail.variation_index.nil?
          variation_index = detail.variation_index

          reason = detail.reason
          reason_kind = reason.kind

          openfeature_reason = kind_to_reason(reason_kind)

          openfeature_error_code = nil
          if reason_kind == LaunchDarkly::EvaluationReason::ERROR
            openfeature_error_code = error_kind_to_code(reason.error_kind)
          end

          openfeature_variant = nil
          openfeature_variant = variation_index.to_s unless is_default

          ::OpenFeature::SDK::Provider::ResolutionDetails.new(
            value: value,
            error_code: openfeature_error_code,
            error_message: nil,
            reason: openfeature_reason,
            variant: openfeature_variant,
            flag_metadata: flag_metadata(reason, is_default ? nil : variation_index)
          )
        end

        #
        # @param reason [LaunchDarkly::EvaluationReason]
        # @param variation_index [Integer, nil]
        #
        # @return [Hash]
        #
        private def flag_metadata(reason, variation_index)
          metadata = {}

          metadata[VARIATION_INDEX_KEY] = variation_index unless variation_index.nil?
          metadata[IN_EXPERIMENT_KEY] = true if reason.in_experiment
          metadata[RULE_INDEX_KEY] = reason.rule_index unless reason.rule_index.nil?
          metadata[RULE_ID_KEY] = reason.rule_id unless reason.rule_id.nil?
          metadata[PREREQUISITE_KEY_KEY] = reason.prerequisite_key unless reason.prerequisite_key.nil?
          metadata[BIG_SEGMENTS_STATUS_KEY] = reason.big_segments_status.to_s unless reason.big_segments_status.nil?

          metadata
        end

        #
        # @param kind [Symbol]
        #
        # @return [String]
        #
        private def kind_to_reason(kind)
          case kind
          when LaunchDarkly::EvaluationReason::OFF
            ::OpenFeature::SDK::Provider::Reason::DISABLED
          when LaunchDarkly::EvaluationReason::TARGET_MATCH
            ::OpenFeature::SDK::Provider::Reason::TARGETING_MATCH
          when LaunchDarkly::EvaluationReason::ERROR
            ::OpenFeature::SDK::Provider::Reason::ERROR
          else
            # NOTE: FALLTHROUGH, RULE_MATCH, PREREQUISITE_FAILED intentionally
            kind.to_s
          end
        end

        #
        # @param error_kind [Symbol]
        #
        # @return [String]
        #
        private def error_kind_to_code(error_kind)
          return ::OpenFeature::SDK::Provider::ErrorCode::GENERAL if error_kind.nil?

          case error_kind
          when LaunchDarkly::EvaluationReason::ERROR_CLIENT_NOT_READY
            ::OpenFeature::SDK::Provider::ErrorCode::PROVIDER_NOT_READY
          when LaunchDarkly::EvaluationReason::ERROR_FLAG_NOT_FOUND
            ::OpenFeature::SDK::Provider::ErrorCode::FLAG_NOT_FOUND
          when LaunchDarkly::EvaluationReason::ERROR_MALFORMED_FLAG
            ::OpenFeature::SDK::Provider::ErrorCode::PARSE_ERROR
          when LaunchDarkly::EvaluationReason::ERROR_USER_NOT_SPECIFIED
            ::OpenFeature::SDK::Provider::ErrorCode::TARGETING_KEY_MISSING
          else
            # NOTE: EXCEPTION_ERROR intentionally omitted
            ::OpenFeature::SDK::Provider::ErrorCode::GENERAL
          end
        end
      end
    end
  end
end
