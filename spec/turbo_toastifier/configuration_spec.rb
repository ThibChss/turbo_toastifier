# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TurboToastifier::Configuration do
  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(TurboToastifier.configuration).to be_a(TurboToastifier::Configuration)
    end

    it 'returns the same instance on multiple calls' do
      first = TurboToastifier.configuration
      second = TurboToastifier.configuration

      expect(first).to eq(second)
    end
  end

  describe '.configure' do
    it 'yields the configuration instance' do
      TurboToastifier.configure do |config|
        expect(config).to be_a(TurboToastifier::Configuration)
      end
    end

    it 'allows setting limit' do
      TurboToastifier.configure do |config|
        config.limit = 5
      end

      expect(TurboToastifier.configuration.limit).to eq(5)
    end

    it 'allows setting duration' do
      TurboToastifier.configure do |config|
        config.duration = 6
      end

      expect(TurboToastifier.configuration.duration).to eq({ default: 6 })
    end

    it 'allows setting duration as a hash' do
      TurboToastifier.configure do |config|
        config.duration = { notice: 4, alert: 0 }
      end

      expect(TurboToastifier.configuration.duration).to eq({ notice: 4, alert: 0 })
    end

    it 'normalizes duration_for with integer duration' do
      TurboToastifier.configure do |config|
        config.duration = 6
      end

      expect(TurboToastifier.configuration.duration_for(:notice)).to eq(6)
      expect(TurboToastifier.configuration.duration_for(:alert)).to eq(6)
    end

    it 'normalizes duration_for with hash duration' do
      TurboToastifier.configure do |config|
        config.duration = { notice: 4, alert: 0 }
      end

      expect(TurboToastifier.configuration.duration_for(:notice)).to eq(4)
      expect(TurboToastifier.configuration.duration_for(:alert)).to eq(0)
    end
  end

  describe 'default values' do
    before do
      # Reset to defaults
      TurboToastifier.configuration.limit = 0
      TurboToastifier.configuration.duration = 4
    end

    it 'has default limit of 0' do
      expect(TurboToastifier.configuration.limit).to eq(0)
    end

    it 'has default duration of 4' do
      expect(TurboToastifier.configuration.duration).to eq({ default: 4 })
      expect(TurboToastifier.configuration.duration_for(:notice)).to eq(4)
    end
  end
end
