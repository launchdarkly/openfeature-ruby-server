# LaunchDarkly OpenFeature provider for the Server-Side SDK for Ruby

[![Gem Version](https://badge.fury.io/rb/launchdarkly-openfeature-server-sdk.svg)](http://badge.fury.io/rb/launchdarkly-openfeature-server-sdk)

[![Run CI](https://github.com/launchdarkly/openfeature-ruby-server/actions/workflows/ci.yml/badge.svg)](https://github.com/launchdarkly/openfeature-ruby-server/actions/workflows/ci.yml)
[![RubyDoc](https://img.shields.io/static/v1?label=docs+-+all+versions&message=reference&color=00add8)](https://www.rubydoc.info/gems/launchdarkly-openfeature-server-sdk)
[![GitHub Pages](https://img.shields.io/static/v1?label=docs+-+latest&message=reference&color=00add8)](https://launchdarkly.github.io/openfeature-ruby-server)

This provider allows for using LaunchDarkly with the OpenFeature SDK for Ruby.

This provider is designed primarily for use in multi-user systems such as web servers and applications. It follows the server-side LaunchDarkly model for multi-user contexts. It is not intended for use in desktop and embedded systems applications.

> [!WARNING]
> This is a beta version. The API is not stabilized and may introduce breaking changes.

> [!NOTE]
> This OpenFeature provider uses production versions of the LaunchDarkly SDK, which adhere to our standard [versioning policy](https://docs.launchdarkly.com/sdk/concepts/versioning).

# LaunchDarkly overview

[LaunchDarkly](https://www.launchdarkly.com) is a feature management platform that serves trillions of feature flags daily to help teams build better software, faster. [Get started](https://docs.launchdarkly.com/home/getting-started) using LaunchDarkly today!

[![Twitter Follow](https://img.shields.io/twitter/follow/launchdarkly.svg?style=social&label=Follow&maxAge=2592000)](https://twitter.com/intent/follow?screen_name=launchdarkly)

## Supported Ruby versions

This version of the LaunchDarkly provider works with Ruby 3.1 and above.

## Getting started

### Requisites

Install the library

```shell
$ gem install launchdarkly-openfeature-server-sdk
```

### Usage

```ruby
require 'open_feature/sdk'
require 'ldclient-rb'
require 'ldclient-openfeature'

provider = LaunchDarkly::OpenFeature::Provider.new(
  'sdk-key',
  LaunchDarkly::Config.new
)

OpenFeature::SDK.configure do |config|
  config.set_provider(provider)
end

# Refer to OpenFeature documentation for getting a client and performing evaluations.
```

Refer to the [SDK reference guide](https://docs.launchdarkly.com/sdk/server-side/ruby) for instructions on getting started with using the SDK.

For information on using the OpenFeature client please refer to the [OpenFeature Documentation](https://docs.openfeature.dev/docs/reference/concepts/evaluation-api/).

## OpenFeature Specific Considerations

LaunchDarkly evaluates contexts, and it can either evaluate a single-context, or a multi-context. When using OpenFeature both single and multi-contexts must be encoded into a single `EvaluationContext`. This is accomplished by looking for an attribute named `kind` in the `EvaluationContext`.

There are 4 different scenarios related to the `kind`:
1. There is no `kind` attribute. In this case the provider will treat the context as a single context containing a "user" kind.
2. There is a `kind` attribute, and the value of that attribute is "multi". This will indicate to the provider that the context is a multi-context.
3. There is a `kind` attribute, and the value of that attribute is a string other than "multi". This will indicate to the provider a single context of the kind specified.
4. There is a `kind` attribute, and the attribute is not a string. In this case the value of the attribute will be discarded, and the context will be treated as a "user". An error message will be logged.

The `kind` attribute should be a string containing only contain ASCII letters, numbers, `.`, `_` or `-`.

The OpenFeature specification allows for an optional targeting key, but LaunchDarkly requires a key for evaluation. A targeting key must be specified for each context being evaluated. It may be specified using either `targeting_key`, as it is in the OpenFeature specification, or `key`, which is the typical LaunchDarkly identifier for the targeting key. If a `targeting_key` and a `key` are specified, then the `targeting_key` will take precedence.

There are several other attributes which have special functionality within a single or multi-context.
- A key of `privateAttributes`. Must be an array of string values. 
- A key of `anonymous`. Must be a boolean value. 
- A key of `name`. Must be a string.

### Examples

#### A single user context

```ruby
context = EvaluationContext(key: "the-key")
```

#### A single context of kind "organization"

```ruby
context = EvaluationContext(key: "org-key", kind: "organization")
```

#### A multi-context containing a "user" and an "organization"

```ruby
attributes = {
    kind: "multi",
    organization: {
        name: "the-org-name",
        key, "my-org-key",
        myCustomAttribute, "myAttributeValue"
    },
    user: {
        key: "my-user-key",
        anonymous, true
    }
}
context = EvaluationContext(**attributes)
```

#### Setting private attributes in a single context

```ruby
attributes = {
    key: "org-key",
    kind: "organization",
    myCustomAttribute: "myAttributeValue",
    privateAttributes: ["myCustomAttribute"]
}

context = EvaluationContext(**attributes)
```

#### Setting private attributes in a multi-context

```ruby
attributes = {
    kind: "organization",
    organization: {
        name: "the-org-name",
        key: "my-org-key",
        # This will ONLY apply to the "organization" attributes.
        privateAttributes: ["myCustomAttribute"],
        # This attribute will be private.
        myCustomAttribute: "myAttributeValue",
    },
    user: [
        key: "my-user-key",
        anonymous = > true,
        # This attribute will not be private.
        myCustomAttribute: "myAttributeValue",
    ]
}

context = EvaluationContext(**attributes)
```

## Learn more

Check out our [documentation](http://docs.launchdarkly.com) for in-depth instructions on configuring and using LaunchDarkly. You can also head straight to the [complete reference guide for this SDK](https://docs.launchdarkly.com/sdk/server-side/ruby).

The authoritative description of all properties and methods is in the [ruby documentation](https://launchdarkly.github.io/openfeature-ruby-server/).

## Contributing

We encourage pull requests and other contributions from the community. Check out our [contributing guidelines](CONTRIBUTING.md) for instructions on how to contribute to this SDK.

## About LaunchDarkly

* LaunchDarkly is a continuous delivery platform that provides feature flags as a service and allows developers to iterate quickly and safely. We allow you to easily flag your features and manage them from the LaunchDarkly dashboard.  With LaunchDarkly, you can:
    * Roll out a new feature to a subset of your users (like a group of users who opt-in to a beta tester group), gathering feedback and bug reports from real-world use cases.
    * Gradually roll out a feature to an increasing percentage of users, and track the effect that the feature has on key metrics (for instance, how likely is a user to complete a purchase if they have feature A versus feature B?).
    * Turn off a feature that you realize is causing performance problems in production, without needing to re-deploy, or even restart the application with a changed configuration file.
    * Grant access to certain features based on user attributes, like payment plan (eg: users on the ‘gold’ plan get access to more features than users in the ‘silver’ plan). Disable parts of your application to facilitate maintenance, without taking everything offline.
* LaunchDarkly provides feature flag SDKs for a wide variety of languages and technologies. Check out [our documentation](https://docs.launchdarkly.com/sdk) for a complete list.
* Explore LaunchDarkly
    * [launchdarkly.com](https://www.launchdarkly.com/ "LaunchDarkly Main Website") for more information
    * [docs.launchdarkly.com](https://docs.launchdarkly.com/  "LaunchDarkly Documentation") for our documentation and SDK reference guides
    * [apidocs.launchdarkly.com](https://apidocs.launchdarkly.com/  "LaunchDarkly API Documentation") for our API documentation
    * [blog.launchdarkly.com](https://blog.launchdarkly.com/  "LaunchDarkly Blog Documentation") for the latest product updates

