# frozen_string_literal: true

require_relative 'configuration/dismiss'

module TurboToastifier
  class Configuration
    attr_accessor :limit, :flash_message_partial, :flash_container_partial
    attr_reader :duration, :dismiss

    DEFAULT_DURATION = 4
    DEFAULT_DURATION_CONFIG = { default: DEFAULT_DURATION }.freeze
    DEFAULT_LIMIT = 0
    DEFAULT_DISMISS = :button
    DEFAULT_FLASH_MESSAGE_PARTIAL = 'turbo_toastifier/flash_message'
    DEFAULT_FLASH_CONTAINER_PARTIAL = 'turbo_toastifier/flash_container'

    private_constant :DEFAULT_DURATION, :DEFAULT_DURATION_CONFIG,
                     :DEFAULT_LIMIT, :DEFAULT_DISMISS,
                     :DEFAULT_FLASH_MESSAGE_PARTIAL, :DEFAULT_FLASH_CONTAINER_PARTIAL

    def initialize
      @limit = DEFAULT_LIMIT
      @dismiss = Dismiss.new(DEFAULT_DISMISS)
      self.duration = DEFAULT_DURATION_CONFIG
      @flash_message_partial = DEFAULT_FLASH_MESSAGE_PARTIAL
      @flash_container_partial = DEFAULT_FLASH_CONTAINER_PARTIAL
    end

    def dismiss=(value)
      @dismiss = Dismiss.new(value)
    end

    def duration=(value)
      @duration = normalize_duration(value)
    end

    def duration_for(flash_type)
      duration.fetch(flash_type.to_sym, duration[:default])
    end

    private

    def normalize_duration(value)
      if value.is_a?(Hash)
        value.transform_keys(&:to_sym).merge(DEFAULT_DURATION_CONFIG)
      else
        { default: value }
      end
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
