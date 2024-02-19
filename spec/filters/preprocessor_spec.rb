# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/preprocessor'
require 'logstash/filters/gramdict'

describe Preprocessor do
  let(:gram_dict) { GramDict.new }
  let(:logformat) { '<date> <time> <message>' }
  let(:content_specifier) { 'message' }
  let(:dynamic_token_threshold) { 0.5 }
  let(:regexes) { ["(\d+.){3}\d+"] }
  let(:preprocessor) { Preprocessor.new(gram_dict, logformat, content_specifier, regexes) }

  describe '#regex_generator' do
    it 'generates a regex based on log format' do
      logformat = '<date> <time> <message>'
      regex = preprocessor.send(:regex_generator, logformat)
      expect(regex).to be_a(Regexp)
      expect('2023-01-01 10:00:00 Sample Log Message').to match(regex)
    end
  end

  describe '#preprocess_known_dynamic_tokens' do
    let(:log_line) { 'User logged in from IP 192.168.1.1' }
    let(:regexes) { [/User/] }

    it 'returns processed log line and dynamic tokens dictionary' do
      processed_log, dynamic_tokens = preprocessor.preprocess_known_dynamic_tokens(log_line, regexes)
      expect(processed_log).not_to include('User')
      expect(processed_log).to include('<*>')
      expect(dynamic_tokens).to be_a(Hash)
      expect(dynamic_tokens.keys).to include('global_processed_dynamic_token_1')
    end

    context 'with general regexes applied' do
      it 'replaces both specific and general dynamic tokens with "<*>"' do
        processed_log = preprocessor.preprocess_known_dynamic_tokens(log_line, regexes)
        expect(processed_log).not_to include('192.168.1.1')
        expect(processed_log).not_to include('User')
        expect(processed_log).to include('<*>').twice
      end
    end

    context 'when extracting dynamic tokens' do
      it 'correctly extracts and stores dynamic tokens with indices' do
        _, dynamic_tokens = preprocessor.preprocess_known_dynamic_tokens(log_line, [/user/i])
        expect(dynamic_tokens['manual_processed_dynamic_token_1']).to eq('User')
      end
    end

    context 'when no matching tokens are found' do
      let(:unmatched_log_line) { 'Static log message without dynamic content' }

      it 'returns the log line unchanged and an empty dynamic tokens dictionary' do
        processed_log, dynamic_tokens = preprocessor.preprocess_known_dynamic_tokens(unmatched_log_line, regexes)
        expect(processed_log).to eq(" #{unmatched_log_line}")
        expect(dynamic_tokens).to be_empty
      end
    end
  end

  describe '#token_splitter' do
    it 'splits a log line into tokens when a match is found' do
      log_line = '2023-01-01 10:00:00 Sample Log Message'
      tokens = preprocessor.token_splitter(log_line)
      expect(tokens).to be_an(Array)
      expect(tokens).to eq([%w[Sample Log Message], {}])
    end

    it 'returns nil when no match is found in the log line' do
      log_line = ''
      tokens = preprocessor.token_splitter(log_line)
      expect(tokens).to eq([nil, nil])
    end
  end

  describe '#process_log_event' do
    let(:log_event) { '2023-01-01 10:00:00 Sample Log Event' }
    let(:threshold) { 0.5 }

    before do
      allow(preprocessor).to receive(:token_splitter).and_call_original
      allow(gram_dict).to receive(:upload_grams)
      allow(gram_dict).to receive(:single_gram_upload)
      allow(gram_dict).to receive(:double_gram_upload)
      allow(gram_dict).to receive(:tri_gram_upload)
    end

    it 'calls token_splitter with the log event' do
      preprocessor.process_log_event(log_event, dynamic_token_threshold, true)
      expect(preprocessor).to have_received(:token_splitter).with(log_event)
    end

    context 'when tokens are extracted from log event' do
      let(:tokens) { %w[Sample Log Event] }

      before do
        allow(preprocessor).to receive(:token_splitter).and_return([tokens, {}])
        allow(gram_dict).to receive(:upload_grams)
        preprocessor.process_log_event(log_event, dynamic_token_threshold, true)
      end

      it 'calls upload_grams with extracted tokens' do
        expect(gram_dict).to have_received(:upload_grams)
      end
    end

    context 'when no tokens are extracted from log event (token_splitter returns nil)' do
      before do
        allow(preprocessor).to receive(:token_splitter).and_return(nil)
        allow(gram_dict).to receive(:upload_grams)
        preprocessor.process_log_event(log_event, dynamic_token_threshold, true)
      end

      it 'does not call upload_grams' do
        expect(gram_dict).not_to have_received(:upload_grams)
      end
    end

    context 'when parse is set to false' do
      before do
        allow(Parser).to receive(:new).and_return(double('Parser', parse: nil))
        preprocessor.process_log_event(log_event, dynamic_token_threshold, false)
      end

      it 'does not call parser.parse' do
        expect(Parser).not_to have_received(:new)
      end
    end

    context 'when parse is set to true' do
      before do
        allow(Parser).to receive(:new).and_return(double('Parser', parse: nil))
        preprocessor.process_log_event(log_event, dynamic_token_threshold, true)
      end

      it 'does call parser.parse' do
        expect(Parser).to have_received(:new)
      end
    end
  end
end
