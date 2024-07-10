# frozen_string_literal: true

require_relative "lib/ldclient-openfeature/version"

Gem::Specification.new do |spec|
  spec.name = "launchdarkly-openfeature-server-sdk"
  spec.version = LaunchDarkly::OpenFeature::VERSION
  spec.authors = ["LaunchDarkly"]
  spec.email = ["team@launchdarkly.com"]

  spec.summary = "LaunchDarkly OpenFeature Server SDK"
  spec.description = "A LaunchDarkly provider for use with the OpenFeature SDK"
  spec.homepage = "https://github.com/launchdarkly/openfeature-ruby-server"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/launchdarkly/openfeature-ruby-server"
  spec.metadata["changelog_uri"] = "https://github.com/launchdarkly/openfeature-ruby-server/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "launchdarkly-server-sdk", "~> 8.4.0"
  spec.add_runtime_dependency "openfeature-sdk", "~> 0.4.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
