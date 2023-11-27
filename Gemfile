# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

logstash_path = ENV.fetch('LOGSTASH_PATH', nil)

if Dir.exist?(logstash_path)
  gem 'logstash-core', path: "#{logstash_path}/logstash-core"
  gem 'logstash-core-plugin-api', path: "#{logstash_path}/logstash-core-plugin-api"
end

group :development do
  gem 'execjs', require: false
  gem 'pre-commit', require: false
  gem 'rspec', '~> 3.12'
  gem 'rubocop', require: false
end
