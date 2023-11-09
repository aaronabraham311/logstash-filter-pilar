# frozen_string_literal: true

require_relative '../spec_helper'
require 'logstash/filters/pilar'

describe LogStash::Filters::Pilar do
  describe 'Set to Hello World' do
    let(:config) do
      <<-CONFIG
      filter {
        pilar {
          message => "Hello World"
        }
      }
      CONFIG
    end

    sample('message' => 'some text') do
      expect(subject).to include('message')
      expect(subject.get('message')).to eq('Hello World')
    end
  end
end
