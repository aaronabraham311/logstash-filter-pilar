# frozen_string_literal: true

require 'rspec'
require_relative '../spec_helper'
require 'logstash/filters/gramdict'

describe GramDict do
  let(:logformat) { '<date> <time> <message>' }

  subject { GramDict.new() }

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

  describe '#four_gram_upload' do
    let(:four_gram) { 'example four gram' }

    it 'correctly updates the four gram count' do
      expect { subject.four_gram_upload(four_gram) }
        .to change { subject.instance_variable_get(:@four_gram_dict)[four_gram] }.from(nil).to(1)

      expect { subject.four_gram_upload(four_gram) }
        .to change { subject.instance_variable_get(:@four_gram_dict)[four_gram] }.from(1).to(2)
    end
  end
end
