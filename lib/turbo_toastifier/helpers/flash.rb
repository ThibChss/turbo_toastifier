module TurboToastifier
  module Helpers
    module Flash
      BASE_ACTIONS = [
        'animationend->turbo-toastifier-flash-removal#remove',
        'mouseenter->turbo-toastifier-flash-removal#pause',
        'mouseleave->turbo-toastifier-flash-removal#resume'
      ].freeze

      CLICK_ACTIONS = [
        'click->turbo-toastifier-flash-removal#handleClick'
      ].freeze

      private_constant :BASE_ACTIONS, :CLICK_ACTIONS

      def actions(action_arr = BASE_ACTIONS.dup)
        action_arr.push(*CLICK_ACTIONS) if configuration.dismiss.click?

        action_arr.join(' ')
      end

      def toast_message_container(flash_type, **options)
        extra_class = options.delete(:class)
        data = options.delete(:data) || {}
        aria = options.delete(:aria) || {}

        {
          class: toast_message_container_class(flash_type, extra_class),
          role: 'alert',
          aria: toast_message_container_aria(flash_type).merge(aria),
          data: toast_message_container_data(flash_type).merge(data)
        }.merge(options)
      end

      def toast_message_container_tag(flash_type, content = nil, **options, &)
        attributes = toast_message_container(flash_type, **options)

        if block_given?
          content_tag(:div, **attributes, &)
        else
          content_tag(:div, content, **attributes)
        end
      end

      def should_show_close_button?(flash_type)
        configuration.duration_for(flash_type).zero? && configuration.dismiss.button?
      end

      def configuration
        @configuration ||= TurboToastifier.configuration
      end

      private

      def toast_message_container_class(flash_type, extra_class)
        ['flash__message', "--#{flash_type}", extra_class].compact.join(' ')
      end

      def toast_message_container_aria(flash_type)
        {
          live: 'polite',
          atomic: 'true',
          label: "#{flash_type.to_s.humanize} message"
        }
      end

      def toast_message_container_data(flash_type)
        {
          controller: 'turbo-toastifier-flash-removal',
          turbo_toastifier_flash_removal_display_time_value: configuration.duration_for(flash_type),
          turbo_toastifier_flash_removal_dismiss_mode_value: configuration.dismiss.to_sym,
          action: actions
        }
      end
    end
  end
end
