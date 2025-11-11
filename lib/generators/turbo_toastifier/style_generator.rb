# frozen_string_literal: true

module TurboToastifier
  class StyleGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    desc 'Generates a customizable SCSS file for TurboToastifier flash message styles'

    def create_style_file
      template 'turbo_toastifier.scss', 'app/assets/stylesheets/turbo_toastifier.scss'
    end
  end
end
