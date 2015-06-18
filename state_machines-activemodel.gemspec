# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'state_machines/integrations/active_model/version'

Gem::Specification.new do |spec|
  spec.name          = 'state_machines-activemodel'
  spec.version       = StateMachines::Integrations::ActiveModel::VERSION
  spec.authors       = ['Abdelkader Boudih', 'Aaron Pfeifer']
  spec.email         = %w(terminale@gmail.com aaron@pluginaweek.org)
  spec.summary       = 'ActiveModel integration for State Machines'
  spec.description   = 'Adds support for creating state machines for attributes on ActiveModel'
  spec.homepage      = 'https://github.com/state-machines/state_machines-activemodel'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(/^test\//)
  spec.require_paths = ['lib']
  spec.required_ruby_version     = '>= 1.9.3'
  spec.add_dependency 'state_machines', '>= 0.4.0'
  spec.add_dependency 'activemodel', '~> 4.1'

  spec.add_development_dependency 'bundler', '>= 1.6'
  spec.add_development_dependency 'rake', '>= 10'
  spec.add_development_dependency 'appraisal', '>= 1'
  spec.add_development_dependency 'minitest', '~> 5.4'
  spec.add_development_dependency 'minitest-reporters'
end
