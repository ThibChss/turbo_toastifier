# frozen_string_literal: true

module TurboToastifier
  module Controller
    class UnknownScheduleError < StandardError; end

    DEFAULT_TOAST_TYPES = %i[
      notice
      alert
      warning
    ].freeze

    DEFAULT_FALLBACK = {
      action: :redirect,
      status: :see_other
    }.freeze

    private_constant :DEFAULT_TOAST_TYPES,
                     :DEFAULT_FALLBACK

    def toast(type, *messages, schedule: :now, exceptions: [])
      generate_toast(type, *messages, schedule:, exceptions:)
    end

    def toastified_render(component = nil, **kwargs)
      extract_and_set_toasts!(:now, kwargs)

      respond_to do |format|
        format.html { render component, **kwargs } if component.present?
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(:flash, partial: 'turbo_toastifier/flash_message'),
                 **kwargs
        end
      end
    end

    def toastified_redirect(path = nil, **kwargs)
      raise ArgumentError, 'No redirect path given' unless path.present?

      extract_and_set_toasts!(:later, kwargs)
      redirect_to path, **kwargs
    end

    def toastified_turbo_frame(component: nil, fallback: {}, **kwargs)
      if turbo_frame_request?
        if component.present?
          toastified_render(component, **kwargs)
        else
          toastified_render(**kwargs)
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

          toastified_redirect(fallback[:path], **fallback)
        when :render
          toastified_render(fallback[:component], **fallback)
        else
          raise ArgumentError, "Unknown action: #{fallback[:action]}"
        end
      end
    end

    private

    def extract_and_set_toasts!(schedule, options)
      toasts = options.slice(*toast_types).compact_blank
      exceptions = extract_exceptions(options)

      set_toasts(schedule, toasts, exceptions) if toasts.present?
    end

    def set_toasts(schedule, toasts, exceptions = {})
      toasts.each do |type, message|
        generate_toast(type, *Array.wrap(message), schedule:, exceptions: exceptions[type] || [])
      end
    end

    def extract_exceptions(options, exceptions: {})
      toast_types.each do |type|
        exceptions[type] = Array.wrap(options[:"#{type}_exceptions"]) if options.key?(:"#{type}_exceptions")
      end

      exceptions
    end

    def toast_store(schedule)
      case schedule
      when :now then flash.now
      when :later then flash
      else
        raise UnknownScheduleError, "Unknown schedule: #{schedule}"
      end
    end

    def toast_types
      @toast_types ||=
        if defined?(ApplicationController) && ApplicationController.respond_to?(:_flash_types, true)
          ApplicationController.send(:_flash_types)
        else
          DEFAULT_TOAST_TYPES
        end
    end

    def generate_toast(type, *messages, schedule: :now, exceptions: [])
      messages = Array.wrap(messages).compact
      return if messages.blank?

      extracted_messages = messages.map do |message|
        extract_errors_from(message, exceptions:)
      end.flatten.compact

      return if extracted_messages.blank?

      store = toast_store(schedule)
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
