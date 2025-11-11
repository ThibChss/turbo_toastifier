module TurboToastifier
  module Controller
    module TurboFrame
      extend ActiveSupport::Concern

      include TurboToastifier::Controller::Render
      include TurboToastifier::Controller::Redirect

      DEFAULT_FALLBACK = {
        action: :redirect,
        status: :see_other
      }.freeze

      private_constant :DEFAULT_FALLBACK

      def toastified_turbo_frame(component = nil, fallback = {}, **kwargs)
        validate_fallback!(fallback)

        if turbo_frame_request?
          process_turbo_frame_request(component, **kwargs)
        else
          process_fallback(fallback)
        end
      end

      private

      def process_turbo_frame_request(component, **kwargs)
        component.present? ? flash_render(component, **kwargs) : flash_render(**kwargs)
      end

      def process_fallback(fallback = {})
        fallback = DEFAULT_FALLBACK.merge(fallback)

        case fallback[:action]
        when :redirect
          validate_path!(fallback[:path])
          validate_component!(fallback[:component])

          flash_redirect(fallback[:path], **fallback)
        when :render
          flash_render(fallback[:component], **fallback)
        else
          raise ArgumentError, "Unknown action: #{fallback[:action]}"
        end
      end

      def validate_path!(path)
        raise ArgumentError, 'No redirect path given' if path.blank?
      end

      def validate_component!(component)
        raise ArgumentError, 'Cannot redirect to a component' if component.present?
      end

      def validate_fallback!(fallback)
        return if fallback[:path].present? || fallback[:component].present?

        raise ArgumentError, 'No fallback path or component given'
      end
    end
  end
end
