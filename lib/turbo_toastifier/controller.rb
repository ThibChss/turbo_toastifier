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

    def toast_types
      @toast_types ||=
        if defined?(ApplicationController) && ApplicationController.respond_to?(:_flash_types, true)
          ApplicationController.send(:_flash_types)
        else
          DEFAULT_TOAST_TYPES
        end
    end

    private

    def toast(type, *messages, schedule: :now)
      messages = Array.wrap(messages).compact
      return if messages.blank?

      store = toast_store(schedule)
      store[type] = Array.wrap(store[type]).push(*messages)
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

    protected

    def extract_and_set_toasts!(schedule, options)
      toasts = options.slice(*toast_types).compact_blank

      set_toasts(schedule, toasts) if toasts.present?
    end

    def set_toasts(schedule, toasts)
      toasts.each { |type, message| toast(type, *Array.wrap(message), schedule:) }
    end

    def toast_store(schedule)
      case schedule
      when :now then flash.now
      when :later then flash
      else
        raise UnknownScheduleError, "Unknown schedule: #{schedule}"
      end
    end
  end
end
