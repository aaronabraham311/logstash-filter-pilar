# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/parser'

describe Parser do
  let(:tokens_list) { [%w[token1a token1b], %w[token2a token2b token2c], %w[token3a token3b]] }
  let(:single_dict) { { 'token2a' => 2, 'key2' => 2 } }
  let(:double_dict) { { 'token2a^token2b' => 2, 'token2b' => 4 } }
  let(:tri_dict)    { { 'token2a^token2b^token2c' => 5, 'key2' => 6 } }
  let(:threshold)   { 0.5 }

  # Create an instance of parser
  subject(:parser) { Parser.new(tokens_list, single_dict, double_dict, tri_dict, threshold) }

  describe '#initialize' do
    it 'initializes with the correct attributes' do
      expect(parser.instance_variable_get(:@tokens_list)).to eq(tokens_list)
      expect(parser.instance_variable_get(:@single_dict)).to eq(single_dict)
      expect(parser.instance_variable_get(:@double_dict)).to eq(double_dict)
      expect(parser.instance_variable_get(:@tri_dict)).to eq(tri_dict)
      expect(parser.instance_variable_get(:@threshold)).to eq(threshold)
      expect(parser.instance_variable_get(:@entropy_dict)).to eq({})
    end
  end

  describe '#update_entropy_dict' do
    it 'updates the entropy dictionary correctly for new f_score values' do
      f_score_new = 0.75
      parser.update_entropy_dict(f_score_new)

      expect(parser.instance_variable_get(:@entropy_dict)).to eq({ '0.75' => 1 })
    end

    it 'increments the count correctly for existing f_score values' do
      f_score_existing = 0.5

      # Add the f_score twice to simulate existing value
      parser.update_entropy_dict(f_score_existing)
      parser.update_entropy_dict(f_score_existing)

      expect(parser.instance_variable_get(:@entropy_dict)).to eq({ '0.5' => 2 })
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

  describe '#gram_checker' do
    it 'returns the correct dynamic index for a given tokens array' do
      tokens = tokens_list[2]

      dynamic_indices = parser.gram_checker(tokens)

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
      event_string, template_string = parser.parse
      
      expected_event_string = "EventId,EventTemplate\n" \
                                 "e7f6f,token1a <*> \n" \
                                 "e5a48,token2a token2b token2c \n" \
                                 "e733e,token3a <*> \n"

      expected_template_string = "EventTemplate,Occurrences\n" \
                                 "token1a <*> ,1\n" \
                                 "token2a token2b token2c ,1\n" \
                                 "token3a <*> ,1\n"

      expect(event_string).to eq(expected_event_string)
      expect(template_string).to eq(expected_template_string)
    end
  end
end
