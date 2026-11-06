# frozen_string_literal: true

#
# Since LaunchDarkly Ruby SDK 8.19 the data source retries every transport
# failure indefinitely instead of stopping permanently, so an initialization
# that fails within the wait time is routinely followed by a background
# recovery. The provider must report READY when that happens.
#
RSpec.describe LaunchDarkly::OpenFeature::Provider do
  let(:td) {
    td = LaunchDarkly::Integrations::TestData.data_source
    td.update(td.flag("fallthrough-boolean").variation_for_all(true))
    td
  }
  let(:config) { LaunchDarkly::Config.new(data_source: td, send_events: false) }
  let(:provider) { described_class.new("example-key", config) }
  let(:api) { OpenFeature::SDK::API.instance }

  after do
    api.configuration.shutdown
  end

  it "reports READY after a failed initialization once the data source becomes valid" do
    allow(provider.client).to receive(:initialized?).and_return(false)

    expect { api.set_provider_and_wait(provider) }.to raise_error(/unable to initialize/)

    client = api.build_client
    expect(client.provider_status).to eq(OpenFeature::SDK::ProviderState::ERROR)

    # The data source recovering reaches the provider through its registered
    # status listener; drive it the way the SDK broadcaster does on recovery.
    listener = LaunchDarkly::OpenFeature::Impl::DataSourceStatusListener.new(provider)
    listener.update(
      LaunchDarkly::Interfaces::DataSource::Status.new(
        LaunchDarkly::Interfaces::DataSource::Status::VALID, Time.now, nil
      )
    )

    expect(client.provider_status).to eq(OpenFeature::SDK::ProviderState::READY)
  end
end
