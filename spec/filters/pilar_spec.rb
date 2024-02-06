# frozen_string_literal: true

require_relative '../spec_helper'
require 'logstash/filters/pilar'

describe LogStash::Filters::Pilar do
  let(:config) { { 'source_field' => 'sample_log' } }
  subject(:pilar_filter) { described_class.new(config) }

  before do
    pilar_filter.register
  end

  describe 'configuration validation' do
    context 'when threshold is valid' do
      let(:config) { { 'threshold' => 0.5 } }

      it 'registers without errors' do
        expect { described_class.new(config).register }.not_to raise_error
      end
    end
  end

  describe 'registration' do
    it 'correctly register without errors' do
      expect { pilar_filter }.not_to raise_error
    end
  end

  describe 'filtering' do
    sample_log = '- 1120928280 2005.07.09 R21-M0-NB-C:J05-U11 2005-07-09-09.58.00.188544 R21-M0-NB-C:J05-U11 ' \
                 'RAS KERNEL INFO generating core.10299'

    let(:event) { LogStash::Event.new('sample_log' => sample_log) }

    before do
      pilar_filter.filter(event)
    end

    it 'correctly sets the dynamic_tokens field' do
      expect(event.get('dynamic_tokens')).not_to be_nil
    end

    it 'correctly sets the template_string field' do
      expect(event.get('template_string')).not_to be_nil
    end

    it 'correctly sets the raw_log field to the value of the source_field' do
      expect(event.get('raw_log')).to eq(sample_log)
    end
  end

  describe 'line number incrementation' do
    let(:config) { {} } # Default configuration
    let(:sample_log) { 'Sample log content' }
    let(:event1) { LogStash::Event.new('message' => sample_log) }
    let(:event2) { LogStash::Event.new('message' => sample_log) }

    it 'increments line_id for each event' do
      pilar_filter.filter(event1)
      pilar_filter.filter(event2)
      expect(event2.get('line_id')).to eq(event1.get('line_id') + 1)
    end
  end
end
