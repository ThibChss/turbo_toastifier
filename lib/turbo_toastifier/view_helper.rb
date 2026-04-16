# frozen_string_literal: true

require_relative 'helpers/flash'

module TurboToastifier
  module ViewHelper
    include TurboToastifier::Helpers::Flash

    # Renders the flash message container using configured defaults.
    # Configuration is set via TurboToastifier.configure in an initializer.
    def toastified_flash_tag
      render partial: TurboToastifier.configuration.flash_container_partial
    end
  end
end
