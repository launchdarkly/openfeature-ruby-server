# frozen_string_literal: true

RSpec.describe LaunchDarkly::OpenFeature::Provider do
  let(:td) {
    td = LaunchDarkly::Integrations::TestData.data_source
    td.update(td.flag("fallthrough-boolean").variation_for_all(true))
    td
  }
  let(:evaluation_context) { OpenFeature::SDK::EvaluationContext.new(key: "user-key") }
  let(:config) { LaunchDarkly::Config.new(data_source: td) }
  let(:provider) { described_class.new("example-key", config) }

  it "metadata is set correctly" do
    expect(provider.metadata.name).to eq("launchdarkly-openfeature-server")
  end

  it "not providing context returns error" do
    resolution_details = provider.fetch_boolean_value(flag_key: "flag-key", default_value: true)

    expect(resolution_details.value).to eq(true)
    expect(resolution_details.reason).to eq(OpenFeature::SDK::Provider::Reason::ERROR)
    expect(resolution_details.variant).to be_nil
    expect(resolution_details.error_code).to eq(OpenFeature::SDK::Provider::ErrorCode::TARGETING_KEY_MISSING)
  end

  it "evaluation results are converted to details" do
    resolution_details = provider.fetch_boolean_value(flag_key: "fallthrough-boolean", default_value: true, evaluation_context: evaluation_context)

    expect(resolution_details.value).to eq(true)
    expect(resolution_details.reason).to eq("FALLTHROUGH")
    expect(resolution_details.variant).to eq("0")
    expect(resolution_details.error_code).to be_nil
  end

  it "evaluation error results are converted correctly" do
    detail = LaunchDarkly::EvaluationDetail.new(true, nil, LaunchDarkly::EvaluationReason.error(LaunchDarkly::EvaluationReason::ERROR_FLAG_NOT_FOUND))
    allow(LaunchDarkly::LDClient).to receive(:variation_detail).and_return(detail)
    resolution_details = provider.fetch_boolean_value(flag_key: "flag-key", default_value: true, evaluation_context: evaluation_context)

    expect(resolution_details.value).to eq(true)
    expect(resolution_details.reason).to eq(OpenFeature::SDK::Provider::Reason::ERROR)
    expect(resolution_details.variant).to be_nil
    expect(resolution_details.error_code).to eq(OpenFeature::SDK::Provider::ErrorCode::FLAG_NOT_FOUND)
  end

  it "invalid types generate type mismatch results" do
    resolution_details = provider.fetch_string_value(flag_key: "fallthrough-boolean", default_value: "default-value", evaluation_context: evaluation_context)

    expect(resolution_details.value).to eq("default-value")
    expect(resolution_details.reason).to eq(OpenFeature::SDK::Provider::Reason::ERROR)
    expect(resolution_details.variant).to be_nil
    expect(resolution_details.error_code).to eq(OpenFeature::SDK::Provider::ErrorCode::TYPE_MISMATCH)
  end

  [
    [true, false, false, :fetch_boolean_value],
    [false, true, true, :fetch_boolean_value],
    [false, 1, false, :fetch_boolean_value],
    [false, "True", false, :fetch_boolean_value],
    [true, [], true, :fetch_boolean_value],

    ['default-string', 'return-string', 'return-string', :fetch_string_value],
    ['default-string', 1, 'default-string', :fetch_string_value],
    ['default-string', true, 'default-string', :fetch_string_value],

    [1, 2, 2, :fetch_integer_value],
    [1, 2.0, 2, :fetch_integer_value],
    [1, true, 1, :fetch_integer_value],
    [1, false, 1, :fetch_integer_value],
    [1, "", 1, :fetch_integer_value],

    [1.0, 2.0, 2.0, :fetch_float_value],
    [1.0, 2, 2.0, :fetch_float_value],
    [1.0, true, 1.0, :fetch_float_value],
    [1.0, 'return-string', 1.0, :fetch_float_value],

    [['default-value'], ['return-string'], ['return-string'], :fetch_object_value],
    [['default-value'], true, ['default-value'], :fetch_object_value],
    [['default-value'], 1, ['default-value'], :fetch_object_value],
    [['default-value'], 'return-string', ['default-value'], :fetch_object_value],
  ].each do |default_value, return_value, expected_value, method_name|
      it "check method and result match type" do
        td.update(td.flag("check-method-flag").variations(return_value).variation_for_all(0))

        method = provider.method(method_name)
        resolution_details = method.call(flag_key: "check-method-flag", default_value: default_value, evaluation_context: evaluation_context)

        expect(resolution_details.value).to eq(expected_value)
      end
  end
end
