# frozen_string_literal: true

module TurboToastifier
  module Controller
    class UnknownScheduleError < StandardError; end

    DEFAULT_FLASH_TYPES = %i[
      notice
      alert
      warning
    ].freeze

    DEFAULT_FALLBACK = {
      action: :redirect,
      status: :see_other
    }.freeze

    private_constant :DEFAULT_FLASH_TYPES,
                     :DEFAULT_FALLBACK

    # Adds a toast message to the flash.
    #
    # Automatically extracts errors from ActiveRecord objects if passed. For ActiveRecord objects,
    # you can specify exceptions to exclude certain error fields.
    #
    # @param type [Symbol] The flash type (e.g., :notice, :alert, :error)
    # @param messages [Array<String, ActiveRecord::Base>] One or more messages to display.
    #   Can be strings or ActiveRecord objects (errors will be extracted automatically)
    # @param schedule [Symbol] When to show the message: :now (current request) or :later (next request)
    # @param exceptions [Array<Symbol, String>] Error field names to exclude when extracting errors
    #   from ActiveRecord objects (e.g., [:email, :password])
    #
    # @return [void]
    #
    # @example Basic usage with strings
    #   toast(:notice, 'Success message')
    #   toast(:alert, 'Error 1', 'Error 2')
    #
    # @example With ActiveRecord object (errors extracted automatically)
    #   toast(:error, @record)
    #
    # @example With exceptions to exclude certain error fields
    #   toast(:error, @record, exceptions: [:email, :password])
    #
    # @example Mixing ActiveRecord objects and strings
    #   toast(:error, @record, 'Additional error message')
    #
    # @example Schedule for next request
    #   toast(:notice, 'Saved!', schedule: :later)
    def toast(type, *messages, schedule: :now, exceptions: [])
      set_flash_message(type, *messages, schedule:, exceptions:)
    end

    # Renders a component or view with toast messages extracted from kwargs.
    #
    # Extracts toast messages from the kwargs hash and sets them in flash.now (for current request).
    # Supports both HTML and Turbo Stream formats. For ActiveRecord objects, errors are automatically
    # extracted. Use {flash_type}_exceptions to exclude specific error fields.
    #
    # @param component [Symbol, String, Object, nil] The component, view, or partial to render.
    #   Can be a symbol/string for view names, or an object (e.g., Phlex component)
    # @param kwargs [Hash] Additional options passed to render, including toast messages.
    #   Toast messages are extracted using flash type keys (e.g., :notice, :alert, :error).
    #   Use {flash_type}_exceptions to exclude error fields (e.g., error_exceptions: [:email])
    #
    # @return [void]
    #
    # @example Basic usage
    #   flash_render(:index, notice: 'Success!')
    #
    # @example With ActiveRecord object
    #   flash_render(:edit, error: @record)
    #
    # @example With exceptions
    #   flash_render(:edit, error: @record, error_exceptions: [:email, :password])
    #
    # @example Multiple flash types
    #   flash_render(:index, notice: 'Created!', alert: 'Warning message')
    #
    # @example With Phlex component
    #   flash_render(MyComponent.new, notice: 'Rendered!')
    def flash_render(component = nil, **kwargs)
      process_flash_messages!(:now, kwargs)

      respond_to do |format|
        format.html { render component, **kwargs } if component.present?
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(:flash, partial: 'turbo_toastifier/flash_message'),
                 **kwargs
        end
      end
    end

    # Redirects to a path with toast messages extracted from kwargs.
    #
    # Extracts toast messages from the kwargs hash and sets them in flash (for next request).
    # For ActiveRecord objects, errors are automatically extracted. Use {flash_type}_exceptions
    # to exclude specific error fields.
    #
    # @param path [String, Symbol] The redirect path (required)
    # @param kwargs [Hash] Additional options passed to redirect_to, including toast messages.
    #   Toast messages are extracted using flash type keys (e.g., :notice, :alert, :error).
    #   Use {flash_type}_exceptions to exclude error fields (e.g., error_exceptions: [:email])
    #
    # @return [void]
    #
    # @raise [ArgumentError] if path is nil or blank
    #
    # @example Basic usage
    #   flash_redirect(posts_path, notice: 'Post created!')
    #
    # @example With ActiveRecord object
    #   flash_redirect(edit_post_path(@post), error: @post)
    #
    # @example With exceptions
    #   flash_redirect(root_path, error: @record, error_exceptions: [:email, :password])
    #
    # @example Multiple flash types
    #   flash_redirect(posts_path, notice: 'Created!', alert: 'Check your email')
    def flash_redirect(path = nil, **kwargs)
      raise ArgumentError, 'No redirect path given' unless path.present?

      process_flash_messages!(:later, kwargs)
      redirect_to path, **kwargs
    end

    # Handles Turbo Frame requests with toast messages, with fallback for non-frame requests.
    #
    # If the request is a Turbo Frame request, renders the component/view with toast messages.
    # Otherwise, uses the fallback action (default: redirect). Toast messages are extracted
    # from kwargs. For ActiveRecord objects, errors are automatically extracted. Use
    # {flash_type}_exceptions to exclude specific error fields.
    #
    # @param component [Symbol, String, Object, nil] The component, view, or partial to render
    #   when it's a Turbo Frame request
    # @param fallback [Hash] Fallback behavior for non-frame requests.
    #   Options: :action (required, :redirect or :render), :path (required for redirect),
    #   :component (optional for render), :status (optional)
    # @param kwargs [Hash] Additional options, including toast messages.
    #   Toast messages are extracted using flash type keys (e.g., :notice, :alert, :error).
    #   Use {flash_type}_exceptions to exclude error fields (e.g., error_exceptions: [:email])
    #
    # @return [void]
    #
    # @raise [ArgumentError] if fallback action is invalid, redirect path is missing,
    #   or redirect has a component
    #
    # @example Turbo Frame request (renders component)
    #   flash_turbo_frame(component: :form, notice: 'Updated!')
    #
    # @example Non-frame request (redirects by default)
    #   flash_turbo_frame(
    #     component: :form,
    #     notice: 'Updated!',
    #     fallback: { action: :redirect, path: posts_path }
    #   )
    #
    # @example Non-frame request (renders component)
    #   flash_turbo_frame(
    #     component: :form,
    #     notice: 'Updated!',
    #     fallback: { action: :render, component: :index }
    #   )
    #
    # @example With ActiveRecord object and exceptions
    #   flash_turbo_frame(
    #     component: :form,
    #     error: @record,
    #     error_exceptions: [:email],
    #     fallback: { action: :redirect, path: root_path }
    #   )
    def flash_turbo_frame(component: nil, fallback: {}, **kwargs)
      if turbo_frame_request?
        if component.present?
          flash_render(component, **kwargs)
        else
          flash_render(**kwargs)
        end
      else
        fallback = DEFAULT_FALLBACK.merge(fallback)

        case fallback[:action]
        when :redirect
          if fallback[:path].blank?
            raise ArgumentError, 'No redirect path given'
          end

          if fallback[:component].present?
            raise ArgumentError, 'Cannot redirect to a component'
          end

          flash_redirect(fallback[:path], **fallback)
        when :render
          flash_render(fallback[:component], **fallback)
        else
          raise ArgumentError, "Unknown action: #{fallback[:action]}"
        end
      end
    end

    private

    def process_flash_messages!(schedule, options)
      messages = options.slice(*flash_types).compact_blank
      exceptions = extract_exceptions(options)

      prepare_messages(schedule, messages, exceptions) if messages.present?
    end

    def prepare_messages(schedule, messages, exceptions = {})
      messages.each do |type, message|
        set_flash_message(type, *Array.wrap(message), schedule:, exceptions: exceptions[type] || [])
      end
    end

    def extract_exceptions(options, exceptions: {})
      flash_types.each do |type|
        exceptions[type] = Array.wrap(options[:"#{type}_exceptions"]) if options.key?(:"#{type}_exceptions")
      end

      exceptions
    end

    def flash_store(schedule)
      case schedule
      when :now then flash.now
      when :later then flash
      else
        raise UnknownScheduleError, "Unknown schedule: #{schedule}"
      end
    end

    def flash_types
      @flash_types ||=
        if defined?(ApplicationController) && ApplicationController.respond_to?(:_flash_types, true)
          ApplicationController.send(:_flash_types)
        else
          DEFAULT_FLASH_TYPES
        end
    end

    def set_flash_message(type, *messages, schedule: :now, exceptions: [])
      messages = Array.wrap(messages).compact
      return if messages.blank?

      extracted_messages = messages.map do |message|
        extract_errors_from(message, exceptions:)
      end.flatten.compact

      return if extracted_messages.blank?

      store = flash_store(schedule)
      store[type] = Array.wrap(store[type]).push(*extracted_messages)
    end

    def extract_errors_from(record, exceptions: [])
      return record unless record.respond_to?(:errors) && record.errors.respond_to?(:to_hash)

      errors = record.errors.to_hash(full_messages: true)
      return [] if errors.empty?

      excepted_keys = Array.wrap(exceptions).map(&:to_sym)
      errors.except(*excepted_keys).values.flatten
    end
  end
end
