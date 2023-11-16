# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/gramdict'

describe GramDict do
  let(:separator) { ',' }
  let(:logformat) { '<date> <time> <message>' }
  let(:regex) { /(\d+\.)\{3}\d+/ }
  let(:ratio) { 0.5 }

  subject { GramDict.new(separator, logformat, regex, ratio) }

  describe '#initialize' do
    it 'initializes with the correct attributes' do
      expect(subject.instance_variable_get(:@separator)).to eq(separator)
      expect(subject.instance_variable_get(:@logformat)).to eq(logformat)
      expect(subject.instance_variable_get(:@regex)).to eq(regex)
      expect(subject.instance_variable_get(:@ratio)).to eq(ratio)
    end
  end

  describe '#regex_generator' do
    it 'generates a regular expression based on the log format' do
      format_regex = subject.send(:regex_generator, logformat)
      expect(format_regex).to be_a(Regexp)
      expect(format_regex).to match('<date> <time> <message>')
    end
  end
end
