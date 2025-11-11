# frozen_string_literal: true

module TurboToastifier
  module Controller
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
      TurboToastifier::Flash::Preparator
        .new(schedule, self)
        .set_flash_message!(type, *messages, exceptions:)
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
      extend TurboToastifier::Controller::Render

      toastified_render component, **kwargs
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
      extend TurboToastifier::Controller::Redirect

      toastified_redirect path, **kwargs
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
      extend TurboToastifier::Controller::TurboFrame

      toastified_turbo_frame component, fallback, **kwargs
    end
  end
end
