# frozen_string_literal: true

module TurboToastifier
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    desc 'Creates a TurboToastifier initializer file with default configuration'

    def create_initializer
      template 'turbo_toastifier.rb', 'config/initializers/turbo_toastifier.rb'
    end
  end
end
