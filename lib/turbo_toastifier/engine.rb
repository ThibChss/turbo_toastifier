# frozen_string_literal: true

require 'rails'

module TurboToastifier
  class Engine < ::Rails::Engine
    isolate_namespace TurboToastifier

    initializer 'turbo_toastifier.assets' do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join('app', 'assets', 'stylesheets').to_s
        app.config.assets.paths << root.join('app', 'assets', 'javascript').to_s
      end

      # Ensure JavaScript files are served with correct MIME type
      if app.config.respond_to?(:importmap)
        # Importmap will handle the JavaScript files automatically
      end
    end

    initializer 'turbo_toastifier.helpers' do
      ActiveSupport.on_load(:action_controller_base) do
        include TurboToastifier::Controller
      end

      ActiveSupport.on_load(:action_view) do
        include TurboToastifier::ViewHelper
      end
    end

    # NOTE: Importmap paths configuration is handled manually by users
    # In Rails 8, importmap.paths is frozen, so we can't modify it automatically.
    # Users should add the path manually in their config/importmap.rb if needed.
  end
end
