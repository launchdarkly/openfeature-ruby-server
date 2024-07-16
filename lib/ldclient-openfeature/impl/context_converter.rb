# frozen_string_literal: true

require 'ldclient-rb'
require 'open_feature/sdk'

module LaunchDarkly
  module OpenFeature
    module Impl
      class EvaluationContextConverter
        #
        # @param logger [Logger]
        #
        def initialize(logger)
          @logger = logger
        end

        #
        # Create an LDContext from an EvaluationContext.
        #
        # A context will always be created, but the created context may be invalid. Log messages will be written to
        # indicate the source of the problem.
        #
        # @param context [OpenFeature::SDK::EvaluationContext]
        #
        # @return [LaunchDarkly::LDContext]
        #
        def to_ld_context(context)
          kind = context.field('kind')

          return build_multi_context(context) if kind == "multi"

          unless kind.nil? || kind.is_a?(String)
            @logger.warn("'kind' was set to a non-string value; defaulting to user")
            kind = 'user'
          end

          targeting_key = context.targeting_key
          key = context.field('key')
          targeting_key = get_targeting_key(targeting_key, key)

          kind ||= 'user'
          build_single_context(context.fields, kind, targeting_key)
        end

        #
        # @param targeting_key [String, nil]
        # @param key [any]
        #
        # @return [String]
        #
        private def get_targeting_key(targeting_key, key)
          # The targeting key may be set but empty. So we want to treat an empty string as a not defined one. Later it
          # could become null, so we will need to check that.
          if !targeting_key.nil? && targeting_key != "" && key.is_a?(String)
            # There is both a targeting key and a key. It will work, but probably is not intentional.
            @logger.warn("EvaluationContext contained both a 'key' and 'targeting_key'.")
          end

          @logger.warn("A non-string 'key' attribute was provided.") unless key.nil? || key.is_a?(String)

          targeting_key ||= key unless key.nil? || !key.is_a?(String)

          if targeting_key.nil? || targeting_key == "" || !targeting_key.is_a?(String)
            @logger.error("The EvaluationContext must contain either a 'targeting_key' or a 'key' and the type must be a string.")
          end

          targeting_key || ""
        end

        #
        # @param context [OpenFeature::SDK::EvaluationContext]
        #
        # @return [LaunchDarkly::LDContext]
        #
        private def build_multi_context(context)
          contexts = []

          context.fields.each do |kind, attributes|
            next if kind == 'kind'

            unless attributes.is_a?(Hash)
              @logger.warn("Top level attributes in a multi-kind context should be dictionaries")
              next
            end

            key = attributes.fetch(:key, nil)
            targeting_key = attributes.fetch(:targeting_key, nil)

            next unless targeting_key.nil? || targeting_key.is_a?(String)

            targeting_key = get_targeting_key(targeting_key, key)
            single_context = build_single_context(attributes, kind, targeting_key)

            contexts << single_context
          end

          LaunchDarkly::LDContext.create_multi(contexts)
        end

        #
        # @param attributes [Hash]
        # @param kind [String]
        # @param key [String]
        #
        # @return [LaunchDarkly::LDContext]
        #
        private def build_single_context(attributes, kind, key)
          context = { kind: kind, key: key }

          attributes.each do |k, v|
            next if %w[key targeting_key kind].include? k

            if k == 'name' && v.is_a?(String)
              context[:name] = v
            elsif k == 'name'
              @logger.error("The attribute 'name' must be a string")
              next
            elsif k == 'anonymous' && [true, false].include?(v)
              context[:anonymous] = v
            elsif k == 'anonymous'
              @logger.error("The attribute 'anonymous' must be a boolean")
              next
            elsif k == 'privateAttributes' && v.is_a?(Array)
              private_attributes = []
              v.each do |private_attribute|
                unless private_attribute.is_a?(String)
                  @logger.error("'privateAttributes' must be an array of only string values")
                  next
                end

                private_attributes << private_attribute
              end

              context[:_meta] = { privateAttributes: private_attributes } unless private_attributes.empty?
            elsif k == 'privateAttributes'
              @logger.error("The attribute 'privateAttributes' must be an array")
            else
              context[k.to_sym] = v
            end
          end

          LaunchDarkly::LDContext.create(context)
        end
      end
    end
  end
end
