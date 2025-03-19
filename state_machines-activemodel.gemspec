require_relative 'lib/state_machines/integrations/active_model/version'

Gem::Specification.new do |spec|
  spec.name          = 'state_machines-activemodel'
  spec.version       = StateMachines::Integrations::ActiveModel::VERSION
  spec.authors       = ['Abdelkader Boudih', 'Aaron Pfeifer']
  spec.email         = %w(terminale@gmail.com aaron@pluginaweek.org)
  spec.summary       = 'ActiveModel integration for State Machines'
  spec.description   = 'Adds support for creating state machines for attributes on ActiveModel'
  spec.homepage      = 'https://github.com/state-machines/state_machines-activemodel'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{lib}/**/*') + %w(LICENSE.txt README.md)
  spec.test_files    = Dir.glob('test/**/{*_test,test_*}.rb')
  spec.require_paths = ['lib']
  spec.required_ruby_version     = '>= 3.0.0'
  spec.add_dependency 'state_machines', '>= 0.6.0'
  spec.add_dependency 'activemodel', '>= 6.0'

  spec.add_development_dependency 'bundler', '>= 1.6'
  spec.add_development_dependency 'rake', '>= 10'
  spec.add_development_dependency 'appraisal', '>= 1'
  spec.add_development_dependency 'minitest', '~> 5.4'
  spec.add_development_dependency 'minitest-reporters'
end
