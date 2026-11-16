# frozen_string_literal: true

RSpec.describe LaunchDarkly::OpenFeature::Impl::EvaluationContextConverter do
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  let(:context_converter) { described_class.new(logger) }

  before do
    log_output.reopen
  end

  describe "key handling" do
    it "creates context with only targeting key" do
      context = OpenFeature::SDK::EvaluationContext.new(targeting_key: "user-key")
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq('user-key')
      expect(ld_context.kind).to eq('user')
    end

    it "create context with only key" do
      context = OpenFeature::SDK::EvaluationContext.new(key: "user-key")
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("user-key")
      expect(ld_context.kind).to eq("user")
    end

    it "targeting key takes precedence over attribute key" do
      context = OpenFeature::SDK::EvaluationContext.new(targeting_key: "should-use", kind: "org", key: "do-not-use")
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("should-use")
      expect(ld_context.kind).to eq("org")
    end

    it "key replaces invalid targeting key" do
      context = OpenFeature::SDK::EvaluationContext.new(targeting_key: false, kind: "org", key: "fallback")
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("fallback")
      expect(ld_context.kind).to eq("org")
    end

    it "creates a context with an invalid targeting_key" do
      context = OpenFeature::SDK::EvaluationContext.new(targeting_key: false)
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(false)
      expect(ld_context.key).to be_nil

      expect(log_output.string).to include("The EvaluationContext must contain either a 'targeting_key' or a 'key' and the type must be a string.")
    end

    it "creates a context with an invalid key" do
      context = OpenFeature::SDK::EvaluationContext.new(key: false)
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(false)
      expect(ld_context.key).to be_nil

      expect(log_output.string).to include("A non-string 'key' attribute was provided.")
    end

  end

  describe "kind handling" do
    it "can specify kind" do
      context = OpenFeature::SDK::EvaluationContext.new(key: "org-key", kind: "org")
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("org-key")
      expect(ld_context.kind).to eq("org")
    end

    it "invalid kind is discarded and reset to user" do
      context = OpenFeature::SDK::EvaluationContext.new(key: "org-key", kind: false)
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("org-key")
      expect(ld_context.kind).to eq("user")
    end
  end

  describe "attribute handling" do
    it "test attributes are referenced correctly" do
      context = OpenFeature::SDK::EvaluationContext.new(key: "user-key", kind: "user", anonymous: true, name: "Sandy", lastName: "Beaches")
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("user-key")
      expect(ld_context.kind).to eq("user")
      expect(ld_context[:anonymous]).to be(true)
      expect(ld_context[:name]).to eq("Sandy")
      expect(ld_context[:lastName]).to eq("Beaches")
    end

    it "invalid attributes are ignored" do
      context = OpenFeature::SDK::EvaluationContext.new(key: "user-key", kind: "user", anonymous: true, name: 30, privateAttributes: "testing")
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("user-key")
      expect(ld_context.kind).to eq("user")
      expect(ld_context[:anonymous]).to be(true)
      expect(ld_context[:name]).to be_nil
      expect(ld_context.private_attributes).to eq([])
    end
  end

  describe "attribute value conversion" do
    it "converts instants to UTC without mutating frozen input values" do
      time = Time.new(2026, 11, 16, 9, 30, 0, "+02:00").freeze
      date_time = DateTime.new(2026, 11, 16, 9, 30, 0, "+02:00").freeze
      values = { "time" => time, "date_time" => date_time, "date" => Date.new(2026, 11, 16) }.freeze
      context = OpenFeature::SDK::EvaluationContext.new(key: "user-key", values: values)

      ld_context = context_converter.to_ld_context(context)

      expect(ld_context[:values]).to eq({
        "time" => "2026-11-16T07:30:00Z",
        "date_time" => "2026-11-16T07:30:00Z",
        "date" => "2026-11-16T00:00:00Z",
      })
      expect(time.utc_offset).to eq(7200)
      expect(values["time"]).to equal(time)
    end

    it "recursively converts list and structure values and replaces unsupported values with null" do
      values = [nil, true, false, 42, 1.5, "text", { "nested" => [Time.utc(2026, 11, 16), Object.new] }].freeze
      context = OpenFeature::SDK::EvaluationContext.new(key: "user-key", values: values, unsupported: Object.new)

      ld_context = context_converter.to_ld_context(context)

      expect(ld_context[:values]).to eq([nil, true, false, 42, 1.5, "text", { "nested" => ["2026-11-16T00:00:00Z", nil] }])
      expect(ld_context[:unsupported]).to be_nil
      expect(log_output.string).to include("ERROR", "cannot be converted; using null")
      expect(values.last["nested"].first).to be_a(Time)
    end

    it "preserves fractional seconds in instants used for targeting" do
      time = Time.utc(2026, 11, 16, 0, 0, Rational(3, 2))
      context = OpenFeature::SDK::EvaluationContext.new(key: "user-key", time: time, date_time: time.to_datetime)

      ld_context = context_converter.to_ld_context(context)

      expect(ld_context[:time]).to eq("2026-11-16T00:00:01.500000000Z")
      expect(ld_context[:date_time]).to eq("2026-11-16T00:00:01.500000000Z")
    end

    it "converts custom attribute values inside multi-contexts" do
      context = OpenFeature::SDK::EvaluationContext.new(
        kind: "multi", user: { key: "user-key", signed_up: Time.utc(2026, 11, 16) }, org: { key: "org-key" }
      )

      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.individual_context("user")[:signed_up]).to eq("2026-11-16T00:00:00Z")
    end
  end

  describe "private attribute handling" do
    it "private attributes are processed correctly" do
      attributes = {
        key: "user-key",
        kind: "user",
        address: { street: "123 Easy St", city: "Anytown" },
        name: "Sandy",
        privateAttributes: ["name", "/address/city"],
      }
      context = OpenFeature::SDK::EvaluationContext.new(**attributes)
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("user-key")
      expect(ld_context.kind).to eq("user")
      expect(ld_context.private_attributes).to eq([LaunchDarkly::Reference.create("name"), LaunchDarkly::Reference.create("/address/city")])
    end

    it "ignores invalid private attribute types" do
      context = OpenFeature::SDK::EvaluationContext.new(key: "user-key", privateAttributes: [true])
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.key).to eq("user-key")

      expect(log_output.string).to include("'privateAttributes' must be an array of only string values")
    end
  end

  describe "multi kind context" do
    it "can create multi kind context" do
      attributes = {
        kind: "multi",
        user: { key: "user-key", name: "User name" },
        org: { key: "org-key", name: "Org name" },
      }
      context = OpenFeature::SDK::EvaluationContext.new(**attributes)
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.multi_kind?).to be(true)

      user_context = ld_context.individual_context("user")
      expect(user_context).not_to be_nil
      expect(user_context.key).to eq("user-key")
      expect(user_context.kind).to eq("user")
      expect(user_context[:name]).to eq("User name")

      org_context = ld_context.individual_context("org")
      expect(org_context).not_to be_nil
      expect(org_context.key).to eq("org-key")
      expect(org_context.kind).to eq("org")
      expect(org_context[:name]).to eq("Org name")
    end

    it "multi kind context discards invalid single kind" do
      attributes = {
        kind: "multi",
        user: false,
        org: { key: "org-key", name: "Org name" },
      }
      context = OpenFeature::SDK::EvaluationContext.new(**attributes)
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(true)
      expect(ld_context.multi_kind?).to be(false)
      expect(ld_context.key).to eq("org-key")
      expect(ld_context.kind).to eq("org")
      expect(ld_context[:name]).to eq("Org name")
    end

    it "handles all invalid single-kind contexts" do
      attributes = {
        kind: "multi",
        user: "invalid format",
        org: false,
      }
      context = OpenFeature::SDK::EvaluationContext.new(**attributes)
      ld_context = context_converter.to_ld_context(context)

      expect(ld_context.valid?).to be(false)
      expect(ld_context.multi_kind?).to be(false)
    end
  end
end
