# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "donut_dogmatizer"
  spec.version       = "0.1.0"
  spec.authors       = ["Jaimie Black"]
  spec.email         = ["jblack@hackerone.com"]
  spec.summary       = "A tool to judge your schema"
  spec.description   = "DonutDogmatizer is a Ruby tool that judges your schema."
  spec.homepage      = "https://gitlab.inverselink.com/jblack/donut-dogmatizer"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "bin/*", "*.gemspec", "README.md"]
  spec.bindir        = "bin"
  spec.executables   = ["donut_dogmatizer"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rake", "~> 13.0"
end