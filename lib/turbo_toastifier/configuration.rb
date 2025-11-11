# frozen_string_literal: true

require_relative 'configuration/dismiss'

module TurboToastifier
  class Configuration
    attr_accessor :limit
    attr_reader :duration, :dismiss

    DEFAULT_DURATION = 4
    DEFAULT_DURATION_CONFIG = { default: DEFAULT_DURATION }.freeze
    DEFAULT_LIMIT = 0
    DEFAULT_DISMISS = :button

    private_constant :DEFAULT_DURATION, :DEFAULT_DURATION_CONFIG,
                     :DEFAULT_LIMIT, :DEFAULT_DISMISS

    def initialize
      @limit = DEFAULT_LIMIT
      @dismiss = Dismiss.new(DEFAULT_DISMISS)
      self.duration = DEFAULT_DURATION_CONFIG
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
