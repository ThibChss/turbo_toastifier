module TurboToastifier
  class Configuration
    class Dismiss
      VALID_MODES = %i[
        button
        click
      ].freeze

      def initialize(mode)
        @mode = mode.to_sym

        validate_mode!
      end

      VALID_MODES.each do |mode|
        define_method("#{mode}?") do
          @mode.eql?(mode)
        end
      end

      def to_sym
        @mode
      end

      def to_s
        @mode.to_s
      end

      private

      def validate_mode!
        return if VALID_MODES.include?(@mode)

        raise ArgumentError, "dismiss must be one of: #{VALID_MODES.join(', ')}"
      end
    end
  end
end
