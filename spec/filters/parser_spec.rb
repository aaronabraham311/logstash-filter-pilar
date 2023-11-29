# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/parser'
require 'logstash/filters/gramdict'

describe Parser do
  let(:tokens_list) { [%w[token1a token1b], %w[token2a token2b token2c], %w[token3a token3b]] }
  let(:threshold)   { 0.5 }

  # Create an instance of GramDict
  let(:gramdict) do
    gd = GramDict.new

    # Manually setting the dictionaries
    gd.instance_variable_set(:@single_gram_dict, { 'token2a' => 2, 'key2' => 2 })
    gd.instance_variable_set(:@double_gram_dict, { 'token2a^token2b' => 2, 'token2b' => 4 })
    gd.instance_variable_set(:@tri_gram_dict,    { 'token2a^token2b^token2c' => 5, 'key2' => 6 })

    gd
  end

  # Create an instance of Parser
  subject(:parser) { Parser.new(gramdict, threshold) }

  describe '#initialize' do
    it 'initializes with the correct attributes' do
      expect(parser.instance_variable_get(:@gramdict)).to eq(gramdict)
      expect(parser.instance_variable_get(:@threshold)).to eq(threshold)
    end
  end

  describe '#is_dynamic' do
    let(:dynamic_index) { [] }

    context 'when the token index is zero' do
      it 'identifies the token as dynamic' do
        tokens = tokens_list.first
        index = 0
        expect(parser.is_dynamic(tokens, dynamic_index, index)).to be false
      end
    end

    context 'when the token index is one and does not meet dynamic criteria' do
      it 'identifies the token as not dynamic' do
        tokens = tokens_list[1]
        index = 1
        expect(parser.is_dynamic(tokens, dynamic_index, index)).to be false
      end
    end

    context 'when the token index is greater than one and meets dynamic criteria' do
      it 'identifies the token as dynamic' do
        tokens = tokens_list[1]
        index = 2
        expect(parser.is_dynamic(tokens, dynamic_index, index)).to be false
      end
    end
  end

  describe '#find_dynamic_indices' do
    it 'returns the correct dynamic index for a given tokens array' do
      tokens = tokens_list[2]

      dynamic_indices = parser.find_dynamic_indices(tokens)

      expected_indices = [1]

      expect(dynamic_indices).to eq(expected_indices)
    end
  end

  describe '#template_generator' do
    it 'generates the correct template based on dynamic indices' do
      tokens = tokens_list[1]
      dynamic_indices = [1]

      template = parser.template_generator(tokens, dynamic_indices)
      expected_template = 'token2a <*> token2c '

      expect(template).to eq(expected_template)
    end
  end

  describe '#parse' do
    it 'parses the tokens list and generates strings in the correct format' do
      tokens = tokens_list[1]
      event_string, template_string = parser.parse(tokens)

      expected_event_string = "e5a48,token2a token2b token2c \n"

      expected_template_string = 'token2a token2b token2c '

      expect(event_string).to eq(expected_event_string)
      expect(template_string).to eq(expected_template_string)
    end
  end
end
