# frozen_string_literal: true

module TurboToastifier
  module ViewHelper
    # Renders the flash message container using configured defaults.
    # Configuration is set via TurboToastifier.configure in an initializer.
    def toastified_flash_tag
      render partial: 'turbo_toastifier/flash_container'
    end

    private

    def configuration
      TurboToastifier.configuration
    end
  end
end
