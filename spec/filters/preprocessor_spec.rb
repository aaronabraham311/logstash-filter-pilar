# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/preprocessor'
require 'logstash/filters/gramdict'

describe Preprocessor do
  let(:gram_dict) { GramDict.new }
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
    let(:threshold) { 0.5 }

    before do
      allow(preprocessor).to receive(:token_splitter).and_call_original
      allow(gram_dict).to receive(:upload_grams)
      allow(gram_dict).to receive(:single_gram_upload)
      allow(gram_dict).to receive(:double_gram_upload)
      allow(gram_dict).to receive(:tri_gram_upload)
    end

    it 'calls token_splitter with the log event' do
      preprocessor.process_log_event(log_event, threshold)
      expect(preprocessor).to have_received(:token_splitter).with(log_event)
    end

    context 'when tokens are extracted from log event' do
      let(:tokens) { %w[Sample Log Event] }

      before do
        allow(preprocessor).to receive(:token_splitter).and_return(tokens)
        allow(gram_dict).to receive(:upload_grams)
        preprocessor.process_log_event(log_event, threshold)
      end

      it 'calls upload_grams with extracted tokens' do
        expect(gram_dict).to have_received(:upload_grams)
      end
    end

    context 'when no tokens are extracted from log event (token_splitter returns nil)' do
      before do
        allow(preprocessor).to receive(:token_splitter).and_return(nil)
        allow(gram_dict).to receive(:upload_grams)
        preprocessor.process_log_event(log_event, threshold)
      end

      it 'does not call upload_grams' do
        expect(gram_dict).not_to have_received(:upload_grams)
      end
    end

    it 'updates the template_to_template_id mapping for unique log templates' do
      expect { preprocessor.process_log_event(log_event, threshold) }.to change { preprocessor.instance_variable_get(:@template_to_template_id).length }.by(1)
    end

    it 'does not update the template_to_template_id mapping for repeated log templates' do
      preprocessor.process_log_event(log_event, threshold)
      expect { preprocessor.process_log_event(log_event, threshold) }.not_to change { preprocessor.instance_variable_get(:@template_to_template_id).length }
    end
  end

  describe '#process_seed_log_event' do
    let(:log_event) { '2023-01-01 10:00:00 Sample Seed Log Event' }
    let(:threshold) { 0.5 }

    before do
      allow(preprocessor).to receive(:token_splitter).and_call_original
      allow(gram_dict).to receive(:upload_grams)
    end

    it 'splits log event into tokens and updates gram dictionary without parsing' do
      expect(preprocessor).to receive(:token_splitter).with(log_event).and_return(%w[Sample Seed Log Event])
      expect(gram_dict).to receive(:upload_grams).with(%w[Sample Seed Log Event])
      preprocessor.process_seed_log_event(log_event, threshold)
    end

    it 'does not update gram dictionary if no tokens are extracted' do
      allow(preprocessor).to receive(:token_splitter).and_return(nil)
      expect(gram_dict).not_to receive(:upload_grams)
      preprocessor.process_seed_log_event(log_event, threshold)
    end
  end
end
