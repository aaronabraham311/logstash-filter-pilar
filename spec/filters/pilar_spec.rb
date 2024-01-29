# frozen_string_literal: true

require_relative '../spec_helper'
require 'logstash/filters/pilar'

describe LogStash::Filters::Pilar do
  let(:config) { { 'source_field' => 'sample_log', 'dynamic_token_threshold' => 0.5 } }
  subject(:pilar_filter) { described_class.new(config) }

  before do
    pilar_filter.register
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

    it 'correctlys sets the event_string field' do
      expect(event.get('event_string')).not_to be_nil
    end

    it 'correctly sets the template_string field' do
      expect(event.get('template_string')).not_to be_nil
    end

    it 'correctly sets the raw_log field to the value of the source_field' do
      expect(event.get('raw_log')).to eq(sample_log)
    end
  end
end
