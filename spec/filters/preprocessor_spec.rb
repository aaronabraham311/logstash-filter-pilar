# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/preprocessor'
require 'logstash/filters/gramdict'

describe Preprocessor do
  let(:gram_dict) { double('GramDict') }
  let(:logformat) { '<date> <time> <message>' }
  let(:content_specifier) { 'message' }
  let(:preprocessor) { Preprocessor.new(gram_dict, logformat, content_specifier) }

  describe '#regex_generator' do
    it 'generates a regex based on log format' do
      logformat = '<date> <time> <message>'
      regex = preprocessor.send(:regex_generator, logformat)
      expect(regex).to be_a(Regexp)
      expect('2023-01-01 10:00:00 Sample Log Message').to match(regex)
    end
  end

  describe '#token_splitter' do
    it 'splits a log line into tokens when a match is found' do
      log_line = '2023-01-01 10:00:00 Sample Log Message'
      tokens = preprocessor.token_splitter(log_line)
      expect(tokens).to be_an(Array)
      expect(tokens).to eq(%w[Sample Log Message])
    end

    it 'returns nil when no match is found in the log line' do
      log_line = ''
      tokens = preprocessor.token_splitter(log_line)
      expect(tokens).to be_nil
    end
  end

  describe '#process_log_event' do
    let(:log_event) { '2023-01-01 10:00:00 Sample Log Event' }

    before do
      allow(preprocessor).to receive(:token_splitter).and_call_original
      allow(gram_dict).to receive(:upload_grams)
      allow(gram_dict).to receive(:single_gram_upload)
      allow(gram_dict).to receive(:double_gram_upload)
      allow(gram_dict).to receive(:tri_gram_upload)
    end

    it 'calls token_splitter with the log event' do
      preprocessor.process_log_event(log_event)
      expect(preprocessor).to have_received(:token_splitter).with(log_event)
    end

    context 'when tokens are extracted from log event' do
      let(:tokens) { %w[Sample Log Event] }

      before do
        allow(preprocessor).to receive(:token_splitter).and_return(tokens)
        allow(gram_dict).to receive(:upload_grams)
        preprocessor.process_log_event(log_event)
      end

      it 'calls upload_grams with extracted tokens' do
        expect(gram_dict).to have_received(:upload_grams)
      end
    end

    context 'when no tokens are extracted from log event (token_splitter returns nil)' do
      before do
        allow(preprocessor).to receive(:token_splitter).and_return(nil)
        allow(gram_dict).to receive(:upload_grams)
        preprocessor.process_log_event(log_event)
      end

      it 'does not call upload_grams' do
        expect(gram_dict).not_to have_received(:upload_grams)
      end
    end
  end
end
