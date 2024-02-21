# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/gramdict'

describe GramDict do
  let(:logformat) { '<date> <time> <message>' }
  let(:max_gram_dict_size) { 10_000 }

  subject { GramDict.new(max_gram_dict_size) }

  describe '#single_gram_upload' do
    let(:gram) { 'example' }

    it 'correctly updates the single gram count' do
      expect { subject.single_gram_upload(gram) }
        .to change { subject.instance_variable_get(:@single_gram_dict)[gram] }.from(nil).to(1)

      expect { subject.single_gram_upload(gram) }
        .to change { subject.instance_variable_get(:@single_gram_dict)[gram] }.from(1).to(2)
    end
  end

  describe '#double_gram_upload' do
    let(:double_gram) { 'example gram' }

    it 'correctly updates the double gram count' do
      expect { subject.double_gram_upload(double_gram) }
        .to change { subject.instance_variable_get(:@double_gram_dict)[double_gram] }.from(nil).to(1)

      expect { subject.double_gram_upload(double_gram) }
        .to change { subject.instance_variable_get(:@double_gram_dict)[double_gram] }.from(1).to(2)
    end
  end

  describe '#tri_gram_upload' do
    let(:tri_gram) { 'example tri gram' }

    it 'correctly updates the tri gram count' do
      expect { subject.tri_gram_upload(tri_gram) }
        .to change { subject.instance_variable_get(:@tri_gram_dict)[tri_gram] }.from(nil).to(1)

      expect { subject.tri_gram_upload(tri_gram) }
        .to change { subject.instance_variable_get(:@tri_gram_dict)[tri_gram] }.from(1).to(2)
    end
  end

  describe '#upload_grams' do
    context 'with one token' do
      let(:tokens) { ['token1'] }

      it 'updates only the single gram dictionary' do
        expect { subject.upload_grams(tokens) }
          .to change { subject.single_gram_dict['token1'] }.from(nil).to(1)
        expect(subject.double_gram_dict.count).to eq(0)
        expect(subject.tri_gram_dict.count).to eq(0)
      end
    end

    context 'with two tokens' do
      let(:tokens) { %w[token1 token2] }
      let(:double_gram) { 'token1^token2' }

      it 'updates the single and double gram dictionaries' do
        expect { subject.upload_grams(tokens) }
          .to change { subject.single_gram_dict['token1'] }.from(nil).to(1)
          .and change { subject.single_gram_dict['token2'] }.from(nil).to(1)
          .and change { subject.double_gram_dict[double_gram] }.from(nil).to(1)
        expect(subject.tri_gram_dict.count).to eq(0)
      end
    end

    context 'with three tokens' do
      let(:tokens) { %w[token1 token2 token3] }
      let(:double_gram1) { 'token1^token2' }
      let(:double_gram2) { 'token2^token3' }
      let(:tri_gram) { 'token1^token2^token3' }

      it 'updates the single, double, and triple gram dictionaries' do
        expect { subject.upload_grams(tokens) }
          .to change { subject.single_gram_dict['token1'] }.from(nil).to(1)
          .and change { subject.single_gram_dict['token2'] }.from(nil).to(1)
          .and change { subject.single_gram_dict['token3'] }.from(nil).to(1)
          .and change { subject.double_gram_dict[double_gram1] }.from(nil).to(1)
          .and change { subject.double_gram_dict[double_gram2] }.from(nil).to(1)
          .and change { subject.tri_gram_dict[tri_gram] }.from(nil).to(1)
      end
    end

    context 'with an empty token array' do
      let(:tokens) { [] }

      it 'does not update any gram dictionaries' do
        expect { subject.upload_grams(tokens) }
          .not_to(change { subject.single_gram_dict })

        expect { subject.upload_grams(tokens) }
          .not_to(change { subject.double_gram_dict })

        expect { subject.upload_grams(tokens) }
          .not_to(change { subject.tri_gram_dict })
      end
    end
  end
end
