# frozen_string_literal: true

RSpec.describe LaunchDarkly::OpenFeature::Impl::FlagChangeListener do
  let(:provider) { double(emit_event: nil) }

  it "a flag change is a configuration change" do
    described_class.new(provider).update(LaunchDarkly::Interfaces::FlagChange.new("flag-key"))

    expect(provider).to have_received(:emit_event).with(
      OpenFeature::SDK::ProviderEvent::PROVIDER_CONFIGURATION_CHANGED,
      flags_changed: ["flag-key"]
    )
  end
end
