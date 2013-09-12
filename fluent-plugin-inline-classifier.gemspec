# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-inline-classifier"
  spec.version       = "0.1.0"
  spec.authors       = ["Yoshihisa Tanaka"]
  spec.email         = ["yt.hisa@gmail.com"]
  spec.description   = %q{Fluentd plugin to classify each message and inject the result into it}
  spec.summary       = %q{Fluentd plugin to classify each message and inject the result into it}
  spec.homepage      = ""
  spec.license       = "Apache License, Version 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "fluentd"
  spec.add_runtime_dependency "fluentd"
end
