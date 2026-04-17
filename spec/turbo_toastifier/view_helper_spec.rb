# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TurboToastifier::ViewHelper, type: :helper do
  let(:flash_messages) { ActionDispatch::Flash::FlashHash.new }

  before do
    # Reset configuration to defaults before each test
    TurboToastifier.configuration.limit = 0
    TurboToastifier.configuration.duration = 4
    TurboToastifier.configuration.dismiss = :button
    TurboToastifier.configuration.flash_message_partial = 'turbo_toastifier/flash_message'
    TurboToastifier.configuration.flash_container_partial = 'turbo_toastifier/flash_container'

    # Setup flash on view context
    @view_context.instance_variable_set(:@flash, flash_messages)
    allow(@view_context).to receive(:flash).and_return(flash_messages)
  end

  describe '#toast_message_container' do
    it 'returns default attributes for flash message container' do
      attrs = @view_context.toast_message_container(:notice)

      expect(attrs[:class]).to eq('flash__message --notice')
      expect(attrs[:role]).to eq('alert')
      expect(attrs[:aria]).to include(live: 'polite', atomic: 'true', label: 'Notice message')
      expect(attrs[:data]).to include(
        controller: 'turbo-toastifier-flash-removal',
        turbo_toastifier_flash_removal_display_time_value: 4,
        turbo_toastifier_flash_removal_dismiss_mode_value: :button
      )
      expect(attrs[:data][:action]).to include('animationend->turbo-toastifier-flash-removal#remove')
    end

    it 'merges custom class, aria and data attributes' do
      attrs = @view_context.toast_message_container(
        :alert,
        class: 'my-custom-toast',
        aria: { label: 'Custom alert message' },
        data: { testid: 'toast-alert' }
      )

      expect(attrs[:class]).to eq('flash__message --alert my-custom-toast')
      expect(attrs[:aria]).to include(live: 'polite', atomic: 'true', label: 'Custom alert message')
      expect(attrs[:data]).to include(
        controller: 'turbo-toastifier-flash-removal',
        turbo_toastifier_flash_removal_display_time_value: 4,
        turbo_toastifier_flash_removal_dismiss_mode_value: :button,
        testid: 'toast-alert'
      )
    end

    it 'does not include click action when dismiss mode is :none' do
      TurboToastifier.configuration.dismiss = :none
      attrs = @view_context.toast_message_container(:notice)

      expect(attrs[:data][:action]).not_to include('click->turbo-toastifier-flash-removal#handleClick')
    end
  end

  describe '#toast_message_container_tag' do
    it 'renders a div with default toast container attributes' do
      html = @view_context.toast_message_container_tag(:notice, 'Hello')

      expect(html).to include('class="flash__message --notice"')
      expect(html).to include('role="alert"')
      expect(html).to include('aria-live="polite"')
      expect(html).to include('aria-label="Notice message"')
      expect(html).to include('data-controller="turbo-toastifier-flash-removal"')
      expect(html).to include('data-turbo-toastifier-flash-removal-display-time-value="4"')
      expect(html).to include('data-action="animationend-&gt;turbo-toastifier-flash-removal#remove')
      expect(html).to include('Hello')
    end

    it 'supports block content and custom class overrides' do
      html = @view_context.toast_message_container_tag(:alert, class: 'my-custom-toast') do
        @view_context.content_tag(:span, 'Alert!')
      end

      expect(html).to include('class="flash__message --alert my-custom-toast"')
      expect(html).to include('<span>Alert!</span>')
    end
  end

  describe '#toastified_flash_tag' do
    context 'when flash is empty' do
      it 'renders the flash container' do
        result = @view_context.toastified_flash_tag

        expect(result).to be_a(String)
        expect(result).to include('turbo_frame')
        expect(result).to include('flash')
        expect(result).to include('turbo-toastifier-flash-scroll')
      end

      it 'includes correct data attributes' do
        result = @view_context.toastified_flash_tag

        expect(result).to include('data-controller="turbo-toastifier-flash-scroll"')
      end
    end

    context 'when flash has messages' do
      before do
        flash_messages[:notice] = 'Success message'
        flash_messages[:alert] = 'Error message'
      end

      it 'renders flash messages' do
        result = @view_context.toastified_flash_tag

        expect(result).to include('Success message')
        expect(result).to include('Error message')
      end

      it 'includes correct CSS classes for flash types' do
        result = @view_context.toastified_flash_tag

        expect(result).to include('--notice')
        expect(result).to include('--alert')
      end

      it 'includes flash removal controller on messages' do
        result = @view_context.toastified_flash_tag

        expect(result).to include('turbo-toastifier-flash-removal')
      end
    end

    context 'when flash has multiple messages of same type' do
      before do
        flash_messages[:notice] = ['Message 1', 'Message 2']
      end

      it 'renders all messages' do
        result = @view_context.toastified_flash_tag

        expect(result).to include('Message 1')
        expect(result).to include('Message 2')
      end
    end

    context 'when flash message contains HTML' do
      before do
        flash_messages[:notice] = 'Simple message'
      end

      it 'escapes HTML by default' do
        result = @view_context.toastified_flash_tag

        expect(result).to include('Simple message')
        expect(result).not_to include('<script>')
      end

      it 'allows HTML when message is marked as html_safe' do
        flash_messages[:notice] = '<strong>Bold text</strong>'.html_safe
        result = @view_context.toastified_flash_tag

        expect(result).to include('<strong>Bold text</strong>')
        expect(result).not_to include('&lt;strong&gt;')
      end

      it 'allows links when marked as html_safe' do
        flash_messages[:notice] = '<a href="/posts">View posts</a>'.html_safe
        result = @view_context.toastified_flash_tag

        expect(result).to include('<a href="/posts">View posts</a>')
        expect(result).not_to include('&lt;a')
      end
    end

    context 'with configured limit' do
      before do
        flash_messages[:notice] = ['Message 1', 'Message 2', 'Message 3', 'Message 4', 'Message 5']
      end

      it 'uses configured limit' do
        TurboToastifier.configuration.limit = 3
        result = @view_context.toastified_flash_tag

        expect(result).to include('turbo-toastifier-flash-scroll-max-messages-value="3"')
      end

      it 'uses default limit of 0 when not configured' do
        TurboToastifier.configuration.limit = 0
        result = @view_context.toastified_flash_tag

        expect(result).to include('turbo-toastifier-flash-scroll-max-messages-value="0"')
      end

      it 'renders all messages regardless of limit' do
        TurboToastifier.configuration.limit = 2
        result = @view_context.toastified_flash_tag

        # All messages should be in the DOM, but only 2 will be visible
        expect(result).to include('Message 1')
        expect(result).to include('Message 2')
        expect(result).to include('Message 3')
        expect(result).to include('Message 4')
        expect(result).to include('Message 5')
      end
    end

    context 'with configured duration' do
      before do
        flash_messages[:notice] = 'Test message'
      end

      it 'uses configured duration' do
        TurboToastifier.configuration.duration = 6
        result = @view_context.toastified_flash_tag

        # Check for the escaped HTML attribute (ERB escapes HTML)
        expect(result).to include('data-turbo-toastifier-flash-removal-display-time-value')
        expect(result).to match(/display-time-value="6"/)
      end

      it 'uses configured duration hash' do
        TurboToastifier.configuration.duration = { notice: 5, alert: 0 }
        result = @view_context.toastified_flash_tag

        # Check for the escaped HTML attribute (ERB escapes HTML)
        expect(result).to include('data-turbo-toastifier-flash-removal-display-time-value')
        expect(result).to match(/display-time-value="5"/)
      end

      it 'uses default duration of 4 when not configured' do
        TurboToastifier.configuration.duration = 4
        result = @view_context.toastified_flash_tag

        expect(result).to include('data-turbo-toastifier-flash-removal-display-time-value')
        expect(result).to match(/display-time-value="4"/)
      end

      it 'does not show close button when dismiss mode is :none and duration is 0' do
        TurboToastifier.configuration.dismiss = :none
        TurboToastifier.configuration.duration = 0
        result = @view_context.toastified_flash_tag

        expect(result).not_to include('flash__message-close')
      end
    end
  end
end
