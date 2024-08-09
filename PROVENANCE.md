## Verifying SDK build provenance with the SLSA framework

LaunchDarkly uses the [SLSA framework](https://slsa.dev/spec/v1.0/about) (Supply-chain Levels for Software Artifacts) to help developers make their supply chain more secure by ensuring the authenticity and build integrity of our published SDK packages.

As part of [SLSA requirements for level 3 compliance](https://slsa.dev/spec/v1.0/requirements), LaunchDarkly publishes provenance about our SDK package builds using [GitHub's generic SLSA3 provenance generator](https://github.com/slsa-framework/slsa-github-generator/blob/main/internal/builders/generic/README.md#generation-of-slsa3-provenance-for-arbitrary-projects) for distribution alongside our packages. These attestations are available for download from the GitHub release page for the release version under Assets > `multiple-provenance.intoto.jsonl`.

To verify SLSA provenance attestations, we recommend using [slsa-verifier](https://github.com/slsa-framework/slsa-verifier). Example usage for verifying SDK packages is included below:

<!-- x-release-please-start-version -->
```
# Set the version of the SDK to verify
SDK_VERSION=0.1.0
```
<!-- x-release-please-end -->

```
# Download gem
$ gem fetch launchdarkly-openfeature-server-sdk -v $SDK_VERSION

# Download provenance from Github release
$ curl --location -O \
  https://github.com/launchdarkly/openfeature-ruby-server/releases/download/${SDK_VERSION}/launchdarkly-openfeature-server-sdk-${SDK_VERSION}.gem.intoto.jsonl

# Run slsa-verifier to verify provenance against package artifacts 
$ slsa-verifier verify-artifact \
--provenance-path launchdarkly-openfeature-server-sdk-${SDK_VERSION}.gem.intoto.jsonl \
--source-uri github.com/launchdarkly/openfeature-ruby-server \
launchdarkly-openfeature-server-sdk-${SDK_VERSION}.gem
```

Below is a sample of expected output.

```
Verified signature against tlog entry index 118580648 at URL: https://rekor.sigstore.dev/api/v1/log/entries/24296fb24b8ad77a86b957c02c3834833e7b54e28152fa35cc2a5884994566f7897807c390a9ad83
Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v1.10.0" at commit c1b4bd786f6f7b44d46642f901e6ca95ce4bd170
Verifying artifact launchdarkly-openfeature-server-sdk-0.1.0.gem: PASSED

PASSED: Verified SLSA provenance
```

Alternatively, to verify the provenance manually, the SLSA framework specifies [recommendations for verifying build artifacts](https://slsa.dev/spec/v1.0/verifying-artifacts) in their documentation.

**Note:** These instructions do not apply when building our SDKs from source. 
