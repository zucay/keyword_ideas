# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'keyword_ideas/version'

Gem::Specification.new do |spec|
  spec.name          = "keyword_ideas"
  spec.version       = KeywordIdeas::VERSION
  spec.authors       = ['yuki kawarazuka']
  spec.email         = ['y.kawarazuka+github@gmail.com']

  spec.summary       = 'research keyword ideas via google adwords api'
  spec.description   = 'research keyword ideas via google adwords api'
  spec.homepage      = 'https://github.com/zucay/keyword_ideas'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'thor'
  spec.add_dependency 'google-adwords-api', '~> 0.18'
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency 'pry'
end
