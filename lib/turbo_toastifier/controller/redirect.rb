module TurboToastifier
  module Controller
    module Redirect
      extend ActiveSupport::Concern

      def toastified_redirect(path = nil, **kwargs)
        validate_path!(path)
        preparator(**kwargs).process_flash_messages!

        redirect_to path, **kwargs
      end

      private

      def preparator(**kwargs)
        TurboToastifier::Flash::Preparator.new(:later, self, **kwargs)
      end

      def validate_path!(path)
        raise ArgumentError, 'No redirect path given' unless path.present?
      end
    end
  end
end
