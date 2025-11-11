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

      def should_show_close_button?(flash_type)
        configuration.duration_for(flash_type).zero? && configuration.dismiss.button?
      end

      def configuration
        @configuration ||= TurboToastifier.configuration
      end
    end
  end
end
