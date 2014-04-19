# fluent-plugin-inline-classifier
[![Build Status](https://drone.io/github.com/yosisa/fluent-plugin-inline-classifier/status.png)](https://drone.io/github.com/yosisa/fluent-plugin-inline-classifier/latest)

fluent-plugin-inline-classifier is a plugin for [Fluentd](http://fluentd.org), which provides some features to classify each incoming message. A new keys added into the message and that values hold classified result by user-defined rules.

This is especially useful for converting numeric values into some categories. Because categories are limited, classified messages is easy to grep, or even easy to search by Elasticsearch and Kibana!

The plugin tested on ruby 1.9.3-p448 and fluentd-0.10.45.

## Installation
Using gem:

    $ gem install fluent-plugin-inline-classifier

## Configuration
To use the plugin, specify `type` to `inline_classifier`. Also, `add_prefix` and `remove_prefix` are needed in most cases to prevent the loop.

Each classifying rule is specified in the `rule` section. `rule` sections can be written multiple times.

* `key`: specifies the input key of each message, the corresponding value is used to classify.
* `type`: specifies classifier type, currently supported value is `range` only.
* `store`: specifies the output key of each message, a classified result stores to the corresponding value.
* `classN`: specifies class name and conditions which depend on classifier type. `N` is a integer number. Classifiers evaluate conditions in the order of N and determine what a class is by a first matching condition.

### range classifier
Conditions specified as `min max` form. A min value is inclusive, by contrast, a max value is exclusive. min and max values have a special form `*`, which means the classifier no matter what a value is.

Note: `* *` is not supported currently.

```
<match raw.**>
  type inline_classifier
  add_prefix classified
  remove_prefix raw
  <rule>
    key reqtime
    type range
    store speed
    class1 fast * 0.1
    class2 normal 0.1 0.5
    class3 slow 0.5 *
  </rule>
</match>
```

## License
Apache License, Version 2.0
