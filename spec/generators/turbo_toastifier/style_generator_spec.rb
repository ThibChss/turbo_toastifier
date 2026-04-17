# frozen_string_literal: true

require 'spec_helper'
require 'rails/generators'
require 'fileutils'
require_relative '../../../lib/generators/turbo_toastifier/style_generator'

RSpec.describe TurboToastifier::StyleGenerator do
  let(:destination_root) { File.expand_path('../../tmp/generator_test', __dir__) }

  before do
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, 'app', 'assets', 'stylesheets'))
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  describe 'generated files' do
    context 'with default SCSS format' do
      let(:generator) { TurboToastifier::StyleGenerator.new([], {}, { destination_root: destination_root }) }
      let(:style_path) { File.join(destination_root, 'app', 'assets', 'stylesheets', 'turbo_toastifier.scss') }

      before do
        generator.create_style_file
      end

      it 'creates the style file' do
        expect(File.exist?(style_path)).to be true
      end

      it 'includes nested flash message selectors' do
        content = File.read(style_path)

        expect(content).to include('&__message')
        expect(content).to include('&-content')
        expect(content).to include('&-close')
      end
    end

    context 'with CSS format' do
      let(:generator) { TurboToastifier::StyleGenerator.new([], { format: 'css' }, { destination_root: destination_root }) }
      let(:style_path) { File.join(destination_root, 'app', 'assets', 'stylesheets', 'turbo_toastifier.css') }

      before do
        generator.create_style_file
      end

      it 'creates the css style file' do
        expect(File.exist?(style_path)).to be true
      end

      it 'includes flash container styles' do
        content = File.read(style_path)
        expect(content).to include('.flash')
        expect(content).to include('position: fixed')
      end

      it 'includes plain css flash message selectors' do
        content = File.read(style_path)
        expect(content).to include('.flash__message')
        expect(content).to include('.flash__message-content')
        expect(content).to include('.flash__message-close')
      end

      it 'includes flash type styles' do
        content = File.read(style_path)
        expect(content).to include('.flash__message.--notice')
        expect(content).to include('.flash__message.--alert')
        expect(content).to include('.flash__message.--warning')
      end

      it 'includes animation keyframes' do
        content = File.read(style_path)
        expect(content).to include('@keyframes slide-in')
        expect(content).to include('@keyframes fade-out-slide')
      end

      it 'includes tailwind-friendly import guidance' do
        content = File.read(style_path)
        expect(content).to include('Run `rails generate turbo_toastifier:style --format=css`')
        expect(content).to include('@import "../stylesheets/turbo_toastifier.css";')
      end
    end
  end
end
