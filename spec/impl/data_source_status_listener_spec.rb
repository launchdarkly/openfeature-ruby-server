# frozen_string_literal: true

RSpec.describe LaunchDarkly::OpenFeature::Impl::DataSourceStatusListener do
  let(:provider) { double(emit_event: nil) }
  let(:listener) { described_class.new(provider) }

  def status(state, error = nil)
    LaunchDarkly::Interfaces::DataSource::Status.new(state, Time.now, error)
  end

  it "a valid data source is ready" do
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::VALID))

    expect(provider).to have_received(:emit_event).with(OpenFeature::SDK::ProviderEvent::PROVIDER_READY)
  end

  it "an interrupted data source is stale" do
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::INTERRUPTED))

    expect(provider).to have_received(:emit_event)
      .with(OpenFeature::SDK::ProviderEvent::PROVIDER_STALE, hash_including(:message))
  end

  it "a shut down data source is an error" do
    error = LaunchDarkly::Interfaces::DataSource::ErrorInfo.new(
      LaunchDarkly::Interfaces::DataSource::ErrorInfo::ERROR_RESPONSE, 401, "Unauthorized", Time.now
    )

    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::OFF, error))

    expect(provider).to have_received(:emit_event).with(
      OpenFeature::SDK::ProviderEvent::PROVIDER_ERROR,
      hash_including(error_code: OpenFeature::SDK::Provider::ErrorCode::GENERAL, message: /401/)
    )
  end

  it "a repeated provider status does not emit a second event" do
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::INTERRUPTED))
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::INTERRUPTED))

    expect(provider).to have_received(:emit_event).once
  end

  it "a changed provider status emits an event again" do
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::INTERRUPTED))
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::VALID))
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::INTERRUPTED))

    expect(provider).to have_received(:emit_event).exactly(3).times
  end

  it "an initializing data source does not emit an event" do
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::INITIALIZING))

    expect(provider).not_to have_received(:emit_event)
  end
end
