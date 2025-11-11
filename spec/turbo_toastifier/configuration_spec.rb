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

      expect(TurboToastifier.configuration.duration).to include({ notice: 4, alert: 0 })
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
      TurboToastifier.configuration.dismiss = :button
    end

    it 'has default limit of 0' do
      expect(TurboToastifier.configuration.limit).to eq(0)
    end

    it 'has default duration of 4' do
      expect(TurboToastifier.configuration.duration).to eq({ default: 4 })
      expect(TurboToastifier.configuration.duration_for(:notice)).to eq(4)
    end

    it 'has default dismiss of :button' do
      expect(TurboToastifier.configuration.dismiss.button?).to be true
      expect(TurboToastifier.configuration.dismiss.click?).to be false
      expect(TurboToastifier.configuration.dismiss.to_sym).to eq(:button)
    end
  end

  describe 'dismiss configuration' do
    it 'allows setting dismiss to :button' do
      TurboToastifier.configure do |config|
        config.dismiss = :button
      end

      expect(TurboToastifier.configuration.dismiss.button?).to be true
      expect(TurboToastifier.configuration.dismiss.click?).to be false
      expect(TurboToastifier.configuration.dismiss.to_sym).to eq(:button)
    end

    it 'allows setting dismiss to :click' do
      TurboToastifier.configure do |config|
        config.dismiss = :click
      end

      expect(TurboToastifier.configuration.dismiss.button?).to be false
      expect(TurboToastifier.configuration.dismiss.click?).to be true
      expect(TurboToastifier.configuration.dismiss.to_sym).to eq(:click)
    end

    it 'accepts string values and converts to symbol' do
      TurboToastifier.configure do |config|
        config.dismiss = 'click'
      end

      expect(TurboToastifier.configuration.dismiss.click?).to be true
      expect(TurboToastifier.configuration.dismiss.to_sym).to eq(:click)
    end

    it 'allows using dismiss.click? method' do
      TurboToastifier.configure do |config|
        config.dismiss = :click
      end

      expect(TurboToastifier.configuration.dismiss.click?).to be true
    end

    it 'allows using dismiss.button? method' do
      TurboToastifier.configure do |config|
        config.dismiss = :button
      end

      expect(TurboToastifier.configuration.dismiss.button?).to be true
    end

    it 'raises ArgumentError for invalid dismiss mode' do
      expect do
        TurboToastifier.configure do |config|
          config.dismiss = :invalid
        end
      end.to raise_error(ArgumentError, 'dismiss must be one of: button, click')
    end
  end
end
