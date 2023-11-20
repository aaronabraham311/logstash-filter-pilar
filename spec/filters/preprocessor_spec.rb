# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/preprocessor'
require 'logstash/filters/gramdict'

describe Preprocessor do
  let(:gram_dict) { double('GramDict') }
  let(:regexes) { [/\d{3}-\d{2}-\d{4}/] }
  let(:logformat) { '<date> <time> <message>' }
  let(:preprocessor) { Preprocessor.new(gram_dict, regexes, logformat) }

  describe '#regex_generator' do
    it 'generates a regex based on log format' do
      logformat = '<date> <time> <message>'
      regex = preprocessor.send(:regex_generator, logformat)
      expect(regex).to be_a(Regexp)
      expect('2023-01-01 10:00:00 Sample Log Message').to match(regex)
    end
  end

  describe '#mask_log_event' do
    it 'masks sensitive data in log event' do
      log_event = '2023-01-01 10:00:00 Sensitive Data'
      masked_event = preprocessor.mask_log_event(log_event)
      expect(masked_event).to include('<*>')
    end

    it 'does not alter log event without sensitive data' do
      log_event = 'Regular Log Message'
      masked_event = preprocessor.mask_log_event(log_event)
      expect(masked_event).to eq(" #{log_event}")
    end

    it 'utilizes regexes in @regexes to mask patterns in log event' do
      log_event = 'Error reported 2023-01-01 10:00:00 with ID 123-45-6789'
      masked_event = preprocessor.mask_log_event(log_event)
      expect(masked_event).not_to include('123-45-6789')
      expect(masked_event).to include('<*>')
    end
  end
end
