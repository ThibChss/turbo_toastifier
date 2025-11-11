module TurboToastifier
  module Flash
    class Preparator
      class UnknownScheduleError < StandardError; end

      DEFAULT_FLASH_TYPES = %i[
        notice
        alert
      ].freeze

      private_constant :DEFAULT_FLASH_TYPES

      def initialize(schedule, controller, options = {})
        @schedule = schedule
        @controller = controller
        @options = options
      end

      def process_flash_messages!
        messages = options.slice(*flash_types).compact_blank
        exceptions = extract_exceptions

        prepare_messages(messages, exceptions) if messages.present?
      end

      def set_flash_message!(type, *messages, exceptions: [])
        set_flash_message(type, *messages, exceptions:)
      end

      private

      attr_reader :schedule, :options, :controller

      def prepare_messages(messages, exceptions = {})
        messages.each do |type, message|
          set_flash_message(type, *Array.wrap(message), exceptions: exceptions[type] || [])
        end
      end

      def extract_exceptions(exceptions: {})
        flash_types.each do |type|
          exceptions[type] = Array.wrap(options[:"#{type}_exceptions"]) if options.key?(:"#{type}_exceptions")
        end

        exceptions
      end

      def flash_store
        case schedule
        when :now then controller.flash.now
        when :later then controller.flash
        else
          raise UnknownScheduleError, "Unknown schedule: #{schedule}"
        end
      end

      def flash_types
        @flash_types ||=
          if defined?(ApplicationController) && ApplicationController.respond_to?(:_flash_types, true)
            ApplicationController.send(:_flash_types)
          else
            DEFAULT_FLASH_TYPES
          end
      end

      def set_flash_message(type, *messages, exceptions: [])
        messages = Array.wrap(messages).compact
        return if messages.blank?

        extracted_messages = messages.map do |message|
          extract_errors_from(message, exceptions:)
        end.flatten.compact

        return if extracted_messages.blank?

        store = flash_store
        store[type] = Array.wrap(store[type]).push(*extracted_messages)
      end

      def extract_errors_from(record, exceptions: [])
        return record unless record.respond_to?(:errors) && record.errors.respond_to?(:to_hash)

        errors = record.errors.to_hash(full_messages: true)
        return [] if errors.empty?

        excepted_keys = Array.wrap(exceptions).map(&:to_sym)
        errors.except(*excepted_keys).values.flatten
      end
    end
  end
end
