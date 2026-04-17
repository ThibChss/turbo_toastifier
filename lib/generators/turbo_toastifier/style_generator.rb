# frozen_string_literal: true

module TurboToastifier
  class StyleGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    class_option :format,
                 type: :string,
                 default: 'scss',
                 enum: %w[scss css],
                 desc: 'Stylesheet format to generate (scss or css)'

    desc 'Generates customizable styles for TurboToastifier flash messages'

    def create_style_file
      template template_file_name, destination_file_name
    end

    private

    def style_format
      options.fetch(:format, 'scss')
    end

    def template_file_name
      "turbo_toastifier.#{style_format}"
    end

    def destination_file_name
      "app/assets/stylesheets/turbo_toastifier.#{style_format}"
    end
  end
end
