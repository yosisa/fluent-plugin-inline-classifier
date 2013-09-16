require 'helper'

class ClassifierTest < Test::Unit::TestCase
  def create_classifier
    rules = {'ok' => lambda {|v| v == 'yes'}, 'ng' => lambda {|v| v == 'no'}}
    Fluent::InlineClassifierOutput::Classifier.new('answer', 'class', rules)
  end

  def test_classify
    c = create_classifier
    assert_equal nil, c.classify({})
    assert_equal 'ok', c.classify({'answer' => 'yes'})
    assert_equal 'ng', c.classify({'answer' => 'no'})
    assert_equal nil, c.classify({'answer' => '?'})
  end

  def test_run!
    c = create_classifier
    _do_test = Proc.new {|record, expected|
      c.run!(record)
      assert_equal expected, record
    }

    _do_test.call({}, {})
    _do_test.call({'answer' => 'yes'}, {'answer' => 'yes', 'class' => 'ok'})
    _do_test.call({'answer' => 'no'}, {'answer' => 'no', 'class' => 'ng'})
    _do_test.call({'answer' => '?'}, {'answer' => '?'})
  end
end

class RangeClassifierTest < Test::Unit::TestCase
  def test_classify
    rules = {'fast' => '* 0.1', 'normal' => '0.1 0.5', 'slow' => '0.5 *'}
    c = Fluent::InlineClassifierOutput::RangeClassifier.new('time', 'speed', rules)
    assert_equal 'fast', c.classify({'time' => 0})
    assert_equal 'fast', c.classify({'time' => 0.0999999999})
    assert_equal 'normal', c.classify({'time' => 0.1})
    assert_equal 'normal', c.classify({'time' => 0.4999999999})
    assert_equal 'slow', c.classify({'time' => 0.5})
    assert_equal 'slow', c.classify({'time' => 500})
    assert_equal 'normal', c.classify({'time' => '0.1'})
    assert_equal 'slow', c.classify({'time' => '1'})
  end
end

class InlineClassifierOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    add_prefix cls
    remove_prefix raw
    <rule>
      key reqtime
      type range
      class_fast * 0.1
      class_normal 0.1 0.5
      class_slow 0.5 *
    </rule>
    <rule>
      key status
      store status_type
      type range
      class_2xx 200 300
      class_4xx 400 500
    </rule>
  ]

  def create_driver(conf=CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::InlineClassifierOutput, tag).configure(conf)
  end

  def test_configure
    plugin = create_driver(%[]).instance
    assert_equal 'classified', plugin.add_prefix
    assert_equal nil, plugin.remove_prefix
    assert_equal [], plugin.classifiers

    plugin = create_driver.instance
    assert_equal 'cls', plugin.add_prefix
    assert_equal 'raw', plugin.remove_prefix
    assert_equal 2, plugin.classifiers.length

    classifier = plugin.classifiers[0]
    assert_equal Fluent::InlineClassifierOutput::RangeClassifier, classifier.class
    assert_equal 'reqtime', classifier.key
    assert_equal 'reqtime_class', classifier.store
    assert_equal 3, classifier.rules.length
    assert_equal ['fast', 'normal', 'slow'], classifier.rules.keys.sort

    classifier = plugin.classifiers[1]
    assert_equal Fluent::InlineClassifierOutput::RangeClassifier, classifier.class
    assert_equal 'status', classifier.key
    assert_equal 'status_type', classifier.store
    assert_equal 2, classifier.rules.length
    assert_equal ['2xx', '4xx'], classifier.rules.keys.sort
  end

  def test_strip_tag_prefix
    plugin = create_driver.instance
    assert_equal 'foo', plugin.strip_tag_prefix('foo')
    assert_equal '', plugin.strip_tag_prefix('raw')
    assert_equal 'foo', plugin.strip_tag_prefix('raw.foo')
    assert_equal 'foo.bar', plugin.strip_tag_prefix('raw.foo.bar')
    assert_equal 'foo.raw.bar', plugin.strip_tag_prefix('foo.raw.bar')
  end

  def test_emit
    d = create_driver
    now = Time.now.to_i
    d.expect_emit('cls.test', now, {'reqtime' => 0.2, 'reqtime_class' => 'normal'})
    d.expect_emit('cls', now, {'status' => 200, 'status_type' => '2xx'})
    d.expect_emit('cls.foo', now, {'reqtime' => 1, 'reqtime_class' => 'slow',
                                   'status' => 404, 'status_type' => '4xx'})

    d.run {
      d.emit({'reqtime' => 0.2}, now)
      d.tag = 'raw'
      d.emit({'status' => 200}, now)
      d.tag = 'raw.foo'
      d.emit({'reqtime' => 1, 'status' => 404}, now)
    }

    d = create_driver(%[
      add_prefix cls
    ], 'foo')
    d.expect_emit('cls.foo', now, {'status' => 200})
    d.run {
      d.emit({'status' => 200}, now)
    }
  end
end
