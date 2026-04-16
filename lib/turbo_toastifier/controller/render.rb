module TurboToastifier
  module Controller
    module Render
      extend ActiveSupport::Concern

      def toastified_render(component = nil, **kwargs)
        preparator(**kwargs).process_flash_messages!

        respond_to do |format|
          format.html { render component, **kwargs } if component.present?
          format.turbo_stream { render turbo_stream: flashes, **kwargs }
        end
      end

      def preparator(**kwargs)
        TurboToastifier::Flash::Preparator.new(:now, self, **kwargs)
      end

      def flashes
        turbo_stream.append(:flash, partial: TurboToastifier.configuration.flash_message_partial)
      end
    end
  end
end
