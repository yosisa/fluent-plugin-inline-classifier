# fluent-plugin-inline-classifier

## Configuration
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
