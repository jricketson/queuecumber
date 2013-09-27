# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qcuke/version'

Gem::Specification.new do |spec|
  spec.name          = "qcuke"
  spec.version       = Qcuke::VERSION
  spec.authors       = ["dave@kapoq.com"]
  spec.email         = ["dave@kapoq.com"]
  spec.description   = %q{Quicker cucumber runs}
  spec.summary       = %q{Qcuke lets you distribute your cucumber test build step over
many servers/nodes/machines so you can run them in parallel.}
  spec.homepage      = "http://engineering.lonelyplanet.com"
  spec.license       = "MIT"
  spec.platform      = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 1.9.3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-cucumber"
  spec.add_development_dependency "aws-sdk"
end
