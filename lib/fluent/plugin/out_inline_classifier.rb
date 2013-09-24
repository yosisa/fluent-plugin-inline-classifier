class Fluent::InlineClassifierOutput < Fluent::Output
  Fluent::Plugin.register_output('inline_classifier', self)

  class Classifier
    attr_accessor :key
    attr_accessor :store
    attr_accessor :rules

    def initialize(key, store, rules)
      @key = key
      @store = store
      @rules = rules
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
    def initialize(key, store, rules)
      super
      @rules = []
      rules.each {|name, args|
        args = args.split()
        from = args[0].to_f
        to = args[1].to_f

        if args[0] == '*'
          func = lambda {|v| v.to_f < to}
        elsif args[1] == '*'
          func = lambda {|v| from <= v.to_f}
        else
          func = lambda {|v| v = v.to_f; from <= v and v < to}
        end

        @rules << [name, func]
      }
    end
  end

  CLASSIFIERS = {'range' => RangeClassifier}

  config_param :add_prefix, :string, :default => 'classified'
  config_param :remove_prefix, :string, :default => nil

  attr_accessor :classifiers

  def initialize
    super
    @classifiers = []
  end

  def configure(conf)
    super
    conf.elements.select {|element|
      element.name == 'rule'
    }.each {|element|
      klass = CLASSIFIERS[element['type']]
      key = element['key']
      store = element.fetch('store', key + '_class')
      element.used << 'store'  # To suppress unused configuration warning

      rules = []
      element.keys.each {|key|
        if m = /^class(\d+)$/.match(key)
          rules[m[1].to_i] = element[key].split(' ', 2)
        end
      }

      @classifiers << klass.new(key, store, rules.compact)
    }
  end

  def strip_tag_prefix(tag)
    if tag.start_with?(@remove_prefix)
      head = tag[@remove_prefix.length]
      return '' if head == nil
      return tag[@remove_prefix.length+1..-1] if head == '.'
    end
    return tag
  end

  def emit(tag, es, chain)
    tag = strip_tag_prefix(tag)
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
