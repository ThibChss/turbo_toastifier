# frozen_string_literal: true

module TurboToastifier
  # Internal helper class for flash message views
  # Not exposed to users - only used within gem's views
  class FlashMessageHelper
    attr_reader :duration_config, :default_duration

    def initialize(duration: 4)
      if duration.is_a?(Hash)
        @duration_config = duration.transform_keys(&:to_sym)
        @default_duration = 4
      else
        @duration_config = {}
        @default_duration = duration
      end
    end

    # Fetches the display duration for a specific flash type
    # @param flash_type [String, Symbol] The flash type (e.g., 'notice', 'alert')
    # @return [Integer] The display duration in seconds (0 means never auto-remove)
    def duration_for(flash_type)
      return default_duration if duration_config.empty?

      duration_config.fetch(flash_type.to_sym) do
        duration_config.fetch(flash_type.to_s, default_duration)
      end
    end

    # Determines if the close button should be shown for a flash type
    # @param flash_type [String, Symbol] The flash type (e.g., 'notice', 'alert')
    # @return [Boolean] true if close button should be shown
    def show_close_button?(flash_type)
      duration = duration_for(flash_type)

      duration.nil? || duration.zero?
    end
  end
end
