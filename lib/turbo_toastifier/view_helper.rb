# frozen_string_literal: true

module TurboToastifier
  module ViewHelper
    def toastified_flash_tag
      render partial: 'turbo_toastifier/flash_container', flash: flash
    end
  end
end
