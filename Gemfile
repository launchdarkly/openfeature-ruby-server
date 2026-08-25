# frozen_string_literal: true

source "https://rubygems.org", cooldown: 7

# Specify your gem's dependencies in launchdarkly-openfeature-server-sdk.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.76"
gem "rubocop-performance", "~> 1.25"
gem "rubocop-rake", "~> 0.6"
gem "rubocop-rspec", "~> 3.9"

# Cooldown is configured per source, so exempting our own SDK from it requires a
# second remote for the same registry.
source "https://index.rubygems.org", cooldown: 0 do
  gem "launchdarkly-server-sdk"
end
