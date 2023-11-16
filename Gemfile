# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

logstash_path = ENV['LOGSTASH_PATH']

if Dir.exist?(logstash_path)
  gem 'logstash-core', path: "#{logstash_path}/logstash-core"
  gem 'logstash-core-plugin-api', path: "#{logstash_path}/logstash-core-plugin-api"
end

group :development do
  gem 'pre-commit', require: false
  gem 'rubocop', require: false
end
