# frozen_string_literal: true

require 'spec_helper'
require 'rails/generators'
require 'fileutils'
require_relative '../../../lib/generators/turbo_toastifier/install_generator'

RSpec.describe TurboToastifier::InstallGenerator do
  let(:destination_root) { File.expand_path('../../tmp/generator_test', __dir__) }
  let(:generator) { TurboToastifier::InstallGenerator.new([], {}, { destination_root: destination_root }) }

  before do
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, 'config', 'initializers'))
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  describe 'generated files' do
    before do
      generator.create_initializer
    end

    let(:initializer_path) { File.join(destination_root, 'config', 'initializers', 'turbo_toastifier.rb') }

    it 'creates the initializer file' do
      expect(File.exist?(initializer_path)).to be true
    end

    it 'includes TurboToastifier.configure block' do
      content = File.read(initializer_path)
      expect(content).to include('TurboToastifier.configure')
    end

    it 'includes config.limit setting' do
      content = File.read(initializer_path)
      expect(content).to include('config.limit')
    end

    it 'includes config.duration setting' do
      content = File.read(initializer_path)
      expect(content).to include('config.duration')
    end

    it 'includes comments explaining the configuration' do
      content = File.read(initializer_path)
      expect(content).to include('# Maximum number of messages')
      expect(content).to include('# Display duration')
      expect(content).to include('# Examples:')
    end
  end
end
