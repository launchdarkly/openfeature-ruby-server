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

  it "includes the variation index in the flag metadata" do
    detail = LaunchDarkly::EvaluationDetail.new(true, 1, LaunchDarkly::EvaluationReason::fallthrough)
    resolution_details = details_converter.to_resolution_details(detail)

    expect(resolution_details.flag_metadata).to eq({'variationIndex' => 1})
  end

  it "omits the variation index from the flag metadata for default values" do
    detail = LaunchDarkly::EvaluationDetail.new(true, nil, LaunchDarkly::EvaluationReason::error(LaunchDarkly::EvaluationReason::ERROR_FLAG_NOT_FOUND))
    resolution_details = details_converter.to_resolution_details(detail)

    expect(resolution_details.flag_metadata).to eq({})
  end

  it "includes in experiment in the flag metadata for experiment evaluations" do
    detail = LaunchDarkly::EvaluationDetail.new(true, 1, LaunchDarkly::EvaluationReason::fallthrough(true))
    resolution_details = details_converter.to_resolution_details(detail)

    expect(resolution_details.flag_metadata).to eq({'variationIndex' => 1, 'inExperiment' => true})
  end

  it "omits in experiment from the flag metadata for non-experiment evaluations" do
    detail = LaunchDarkly::EvaluationDetail.new(true, 1, LaunchDarkly::EvaluationReason::fallthrough(false))
    resolution_details = details_converter.to_resolution_details(detail)

    expect(resolution_details.flag_metadata).not_to have_key('inExperiment')
  end

  it "includes the rule in the flag metadata for rule matches" do
    detail = LaunchDarkly::EvaluationDetail.new(true, 1, LaunchDarkly::EvaluationReason::rule_match(2, 'the-rule-id', false))
    resolution_details = details_converter.to_resolution_details(detail)

    expect(resolution_details.flag_metadata).to eq({'variationIndex' => 1, 'ruleIndex' => 2, 'ruleId' => 'the-rule-id'})
  end

  it "includes the prerequisite key in the flag metadata for failed prerequisites" do
    detail = LaunchDarkly::EvaluationDetail.new(true, 1, LaunchDarkly::EvaluationReason::prerequisite_failed('the-prerequisite-key'))
    resolution_details = details_converter.to_resolution_details(detail)

    expect(resolution_details.flag_metadata).to eq({'variationIndex' => 1, 'prerequisiteKey' => 'the-prerequisite-key'})
  end

  it "includes the big segments status in the flag metadata" do
    reason = LaunchDarkly::EvaluationReason::fallthrough.with_big_segments_status(LaunchDarkly::BigSegmentsStatus::STALE)
    detail = LaunchDarkly::EvaluationDetail.new(true, 1, reason)
    resolution_details = details_converter.to_resolution_details(detail)

    expect(resolution_details.flag_metadata).to eq({'variationIndex' => 1, 'bigSegmentsStatus' => 'STALE'})
  end
end
