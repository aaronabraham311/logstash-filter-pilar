# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name          = 'logstash-filter-pilar'
  s.version       = '0.1.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Logstash Filter Plugin for Pilar'
  s.description   = 'A plugin for parsing log events using PILAR'
  s.homepage      = ''
  s.authors       = ['aaronabraham311']
  s.email         = 'aaronabraham311@gmail.com'
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.7.0'

  # Files
  s.files = Dir['lib/**/*', 'spec/**/*', 'vendor/**/*', '*.gemspec', '*.md', 'CONTRIBUTORS', 'Gemfile', 'LICENSE',
                'NOTICE.TXT']
  # Tests

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'filter',
                 'rubygems_mfa_required' => 'true' }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '~> 2.0'
  s.add_development_dependency 'logstash-devutils'
end
