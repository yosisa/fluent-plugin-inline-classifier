# fluent-plugin-inline-classifier

## Configuration
```
<match raw.**>
  type inline_classifier
  add_prefix classified
  remove_prefix raw
  <rule>
    key reqtime
    type float
    classifier range
    class_fast * 0.1
    class_normal 0.1 0.5
    class_slow 0.5 *
  </rule>
</match>
```

## License
Apache License, Version 2.0
