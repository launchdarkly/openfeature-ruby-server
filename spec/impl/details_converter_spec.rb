# frozen_string_literal: true

RSpec.describe LaunchDarkly::OpenFeature::Impl::ResolutionDetailsConverter do
  let(:details_converter) { described_class.new }

  [
    [LaunchDarkly::EvaluationReason::off, OpenFeature::SDK::Provider::Reason::DISABLED],
    [LaunchDarkly::EvaluationReason::target_match, OpenFeature::SDK::Provider::Reason::TARGETING_MATCH],
    [LaunchDarkly::EvaluationReason::error(LaunchDarkly::EvaluationReason::ERROR_MALFORMED_FLAG), OpenFeature::SDK::Provider::Reason::ERROR],
    [LaunchDarkly::EvaluationReason::fallthrough, 'FALLTHROUGH'],
    [LaunchDarkly::EvaluationReason::rule_match(0, 'rule id', false), 'RULE_MATCH'],
    [LaunchDarkly::EvaluationReason::prerequisite_failed('failed-prereq'), 'PREREQUISITE_FAILED'],
  ].each do |ld_reason, of_reason|
    it "converts LD reason (#{ld_reason}) to OF reason (#{of_reason})" do
      detail = LaunchDarkly::EvaluationDetail.new(true, 0, ld_reason)
      resolution_details = details_converter.to_resolution_details(detail)

      expect(resolution_details.reason).to eq(of_reason)
    end
  end

  [
    [LaunchDarkly::EvaluationReason::ERROR_CLIENT_NOT_READY, OpenFeature::SDK::Provider::ErrorCode::PROVIDER_NOT_READY],
    [LaunchDarkly::EvaluationReason::ERROR_FLAG_NOT_FOUND, OpenFeature::SDK::Provider::ErrorCode::FLAG_NOT_FOUND],
    [LaunchDarkly::EvaluationReason::ERROR_MALFORMED_FLAG, OpenFeature::SDK::Provider::ErrorCode::PARSE_ERROR],
    [LaunchDarkly::EvaluationReason::ERROR_USER_NOT_SPECIFIED, OpenFeature::SDK::Provider::ErrorCode::TARGETING_KEY_MISSING],
    [LaunchDarkly::EvaluationReason::ERROR_EXCEPTION, OpenFeature::SDK::Provider::ErrorCode::GENERAL],
  ].each do |ld_error_kind, of_error_code|
    it "converts error kind (#{ld_error_kind}) to OF error code (#{of_error_code})" do
      detail = LaunchDarkly::EvaluationDetail.new(true, 0, LaunchDarkly::EvaluationReason::error(ld_error_kind))
      resolution_details = details_converter.to_resolution_details(detail)

      expect(resolution_details.reason).to eq(OpenFeature::SDK::Provider::Reason::ERROR)
      expect(resolution_details.error_code).to eq(of_error_code)
    end
  end
end
