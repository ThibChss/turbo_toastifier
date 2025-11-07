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
    end

    initializer 'turbo_toastifier.helpers' do
      ActiveSupport.on_load(:action_controller_base) do
        include TurboToastifier::Controller
      end

      ActiveSupport.on_load(:action_view) do
        include TurboToastifier::ViewHelper
      end
    end

    initializer 'turbo_toastifier.stimulus' do |app|
      if defined?(Importmap)
        app.config.importmap.paths << root.join('app', 'assets', 'javascript').to_s
      end
    end
  end
end
