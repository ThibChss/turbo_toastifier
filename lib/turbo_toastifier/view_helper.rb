# frozen_string_literal: true

module TurboToastifier
  module ViewHelper
    def toastified_flash_tag(limit: 0, duration: 4)
      render partial: 'turbo_toastifier/flash_container',
             locals: {
               flash: flash,
               limit: limit,
               duration: duration
             }
    end
  end
end
