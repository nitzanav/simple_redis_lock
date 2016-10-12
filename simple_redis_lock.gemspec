# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_redis_lock/version'

Gem::Specification.new do |spec|
  spec.name          = "simple_redis_lock"
  spec.version       = SimpleRedisLock::VERSION
  spec.authors       = ["Nitzan Aviram"]

  spec.summary       = "Simple and fast lock using one single redis call of 'SET k v NX EX'"
  spec.homepage      = "https://github.com/nitzanav/simple_redis_lock"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "redis", "~> 3.3"
  spec.add_development_dependency "fakeredis", "~> 0.5"
end
