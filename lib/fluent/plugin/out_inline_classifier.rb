class Fluent::InlineClassifierOutput < Fluent::Output
  Fluent::Plugin.register_output('inline_classifier', self)

  class Classifier
    def initialize(key, store, type, rules)
      @key = key
      @store = store
      @type = type
      @rules = rules
    end

    def parse_value(value)
      if @type == 'int'
        value.to_i
      elsif @type == 'float'
        value.to_f
      else
        value
      end
    end

    def classify(record)
      return nil if not record.has_key?(@key)

      target = record[@key]
      @rules.each {|name, func|
        if func.call(target)
          return name
        end
      }
      return nil
    end

    def run!(record)
      if (name = classify(record)) != nil
        record[@store] = name
      end
    end
  end

  class RangeClassifier < Classifier
    def initialize(key, store, type, rules)
      super
      @rules.keys.each {|name|
        args = @rules[name].split()
        from = parse_value(args[0])
        to = parse_value(args[1])

        if args[0] == '*'
          func = lambda {|v| v < to}
        elsif args[1] == '*'
          func = lambda {|v| from <= v}
        else
          func = lambda {|v| from <= v and v < to}
        end

        @rules[name] = func
      }
    end
  end

  CLASSIFIERS = {'range' => RangeClassifier}

  config_param :add_prefix, :string, :default => 'classified'
  config_param :remove_prefix, :string, :default => nil

  def initialize
    super
    @classifiers = []
  end

  def configure(conf)
    super
    conf.elements.select {|element|
      element.name == 'rule'
    }.each {|element|
      klass = CLASSIFIERS[element['classifier']]
      key = element['key']
      store = element.fetch('store', key + '_class')
      type = element['type']

      rules = {}
      element.select {|key, value|
        key.start_with?('class_')
      }.keys.each {|key|
        rules[key[6..-1]] = element[key]
      }

      @classifiers << klass.new(key, store, type, rules)
    }
  end

  def remove_prefix(tag)
    if tag.start_with?(@remove_prefix)
      head = tag[@remove_prefix.length]
      return '' if head == nil
      return tag[@remove_prefix.length+1..-1] if head == '.'
    end
    return tag
  end

  def emit(tag, es, chain)
    tag = remove_prefix(tag)
    tag = tag.length > 0 ? [@add_prefix, tag].join('.') : @add_prefix

    es.each {|time, record|
      @classifiers.each {|classifier|
        classifier.run!(record)
      }
      Fluent::Engine.emit(tag, time, record)
    }

    chain.next
  end
end
