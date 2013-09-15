require 'helper'

class InlineClassifierOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG =%[
  type inline_classifier
  add_prefix classified
  remove_prefix raw
  <rule>
    key reqtime
    type range
    class_fast * 0.1
    class_normal 0.1 0.5
    class_slow 0.5 *
  </rule>
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::OutputTestDriver.new(Fluent::InlineClassifierOutput).configure(conf)
  end

  def test_configure
    plugin = create_driver(%[]).instance
    assert_equal 'classified', plugin.add_prefix
    # assert_equal nil, plugin.remove_prefix
  end

  def test_remove_prefix
    plugin = create_driver.instance
    assert_equal 'foo', plugin.remove_prefix('foo')
    assert_equal '', plugin.remove_prefix('raw')
    assert_equal 'foo', plugin.remove_prefix('raw.foo')
    assert_equal 'foo.bar', plugin.remove_prefix('raw.foo.bar')
    assert_equal 'foo.raw.bar', plugin.remove_prefix('foo.raw.bar')
  end
end
