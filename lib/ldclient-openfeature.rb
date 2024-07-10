# frozen_string_literal: true

require_relative "ldclient-openfeature/impl/context_converter"
require_relative "ldclient-openfeature/impl/details_converter"
require_relative "ldclient-openfeature/provider"
require_relative "ldclient-openfeature/version"

require "logger"

module LaunchDarkly
  #
  # Namespace for the LaunchDarkly OpenFeature provider.
  #
  module OpenFeature
  end
end
