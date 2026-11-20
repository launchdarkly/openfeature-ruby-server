# frozen_string_literal: true

RSpec.describe LaunchDarkly::OpenFeature::Impl::DataSourceOutcomeListener do
  let(:outcome) { Queue.new }
  let(:listener) { described_class.new(outcome) }

  def status(state)
    LaunchDarkly::Interfaces::DataSource::Status.new(state, Time.now, nil)
  end

  it "reports a valid data source" do
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::VALID))

    expect(outcome.pop).to eq(LaunchDarkly::Interfaces::DataSource::Status::VALID)
  end

  it "reports a shut down data source" do
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::OFF))

    expect(outcome.pop).to eq(LaunchDarkly::Interfaces::DataSource::Status::OFF)
  end

  it "does not report a state which leaves the outcome undecided" do
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::INITIALIZING))
    listener.update(status(LaunchDarkly::Interfaces::DataSource::Status::INTERRUPTED))

    expect(outcome).to be_empty
  end
end
