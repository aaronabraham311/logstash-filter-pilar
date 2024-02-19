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
    gd = GramDict.new(10000)

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

  describe '#dynamic_token?' do
    let(:dynamic_index) { [] }

    context 'when the token index is zero' do
      it 'identifies the token as dynamic' do
        tokens = tokens_list.first
        index = 0
        expect(parser.dynamic_token?(tokens, dynamic_index, index)).to be false
      end
    end

    context 'when the token index is one and does not meet dynamic criteria' do
      it 'identifies the token as not dynamic' do
        tokens = tokens_list[1]
        index = 1
        expect(parser.dynamic_token?(tokens, dynamic_index, index)).to be false
      end
    end

    context 'when the token index is greater than one and meets dynamic criteria' do
      it 'identifies the token as dynamic' do
        tokens = tokens_list[1]
        index = 2
        expect(parser.dynamic_token?(tokens, dynamic_index, index)).to be false
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

      template, dynamic_tokens = parser.template_generator(tokens, dynamic_indices)

      # template = template_generator_return_value[0]
      # dynamic_tokens = template_generator_return_value[1]

      expected_template = 'token2a <*> token2c '
      expected_dynamic_tokens = { 'dynamic_token_1' => 'token2b' }

      expect(template).to eq(expected_template)
      expect(dynamic_tokens).to eq(expected_dynamic_tokens)
    end
  end

  describe '#parse' do
    it 'parses the tokens list and generates strings in the correct format' do
      tokens = tokens_list[1]
      template_string, dynamic_tokens = parser.parse(tokens)

      expected_template_string = 'token2a token2b token2c '
      expected_dynamic_tokens = {}

      expect(template_string).to eq(expected_template_string)
      expect(dynamic_tokens).to eq(expected_dynamic_tokens)
    end
  end
end
