# frozen_string_literal: true

module TurboToastifier
  module ViewHelper
    def toastified_flash_tag(max_messages: 0, display_time: 4)
      render partial: 'turbo_toastifier/flash_container',
             locals: {
               flash: flash,
               max_messages: max_messages,
               display_time: display_time
             }
    end
  end
end
