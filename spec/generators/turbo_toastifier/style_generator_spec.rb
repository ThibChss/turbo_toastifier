# frozen_string_literal: true

require 'spec_helper'
require 'rails/generators'
require 'fileutils'
require_relative '../../../lib/generators/turbo_toastifier/style_generator'

RSpec.describe TurboToastifier::StyleGenerator do
  let(:destination_root) { File.expand_path('../../tmp/generator_test', __dir__) }
  let(:generator) { TurboToastifier::StyleGenerator.new([], {}, { destination_root: destination_root }) }

  before do
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, 'app', 'assets', 'stylesheets'))
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  describe 'generated files' do
    before do
      generator.create_style_file
    end

    let(:style_path) { File.join(destination_root, 'app', 'assets', 'stylesheets', 'turbo_toastifier.scss') }

    it 'creates the style file' do
      expect(File.exist?(style_path)).to be true
    end

    it 'includes flash container styles' do
      content = File.read(style_path)
      expect(content).to include('.flash')
      expect(content).to include('position: fixed')
    end

    it 'includes flash message styles' do
      content = File.read(style_path)
      expect(content).to include('&__message')
      expect(content).to include('&-content')
      expect(content).to include('&-close')
    end

    it 'includes flash type styles' do
      content = File.read(style_path)
      expect(content).to include('&__message.--notice')
      expect(content).to include('&__message.--alert')
      expect(content).to include('&__message.--warning')
    end

    it 'includes animation keyframes' do
      content = File.read(style_path)
      expect(content).to include('@keyframes slide-in')
      expect(content).to include('@keyframes fade-out-slide')
    end

    it 'includes customization comments' do
      content = File.read(style_path)
      expect(content).to include('Customization Tips')
      expect(content).to include('Run `rails generate turbo_toastifier:style`')
    end
  end
end
