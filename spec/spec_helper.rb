# frozen_string_literal: true

require 'bundler/setup'
require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'turbo_toastifier'

# Create a minimal Rails app for testing
class TestApp < Rails::Application
  config.root = File.expand_path(__dir__)
  config.eager_load = false
  config.secret_key_base = 'test_secret_key_base'
  config.session_store :cookie_store, key: '_test_session'
  config.active_support.test_order = :random
  config.action_controller.allow_forgery_protection = false

  # Set environment to test
  config.environment = 'test'

  # Disable logging in tests
  config.log_level = :fatal
  config.logger = Logger.new(nil)
end

# Initialize Rails
Rails.application = TestApp
Rails.application.initialize!

# Register turbo_stream MIME type
Mime::Type.register 'text/vnd.turbo-stream.html', :turbo_stream

# Add view paths
view_path = TurboToastifier::Engine.root.join('app', 'views')
ActionController::Base.prepend_view_path(view_path)

# Include RSpec Rails helpers
require 'rspec/rails'
require 'turbo-rails'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include RSpec Rails matchers and helpers
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false

  # Setup for helper specs - use a proper controller class
  config.before(:each, type: :helper) do
    helper_controller_class = Class.new(ActionController::Base) do
      def controller_path
        'test'
      end

      attr_writer :controller_path
    end

    @controller = helper_controller_class.new
    @request = ActionDispatch::TestRequest.create
    @view_context = ActionView::Base.new(
      ActionView::LookupContext.new([TurboToastifier::Engine.root.join('app', 'views').to_s]),
      {},
      @controller
    )
    @view_context.extend TurboToastifier::ViewHelper
    @view_context.extend ActionView::Helpers::TagHelper
    @view_context.extend ActionView::Helpers::UrlHelper
    @view_context.extend ActionView::Helpers::FormHelper
    @view_context.extend ActionView::Helpers::FormTagHelper

    # Mock turbo_frame_tag if turbo-rails is not available
    unless @view_context.respond_to?(:turbo_frame_tag)
      def @view_context.turbo_frame_tag(id, **options, &block)
        content_tag(:turbo_frame, id: id, **options, &block)
      end
    end

    # Mock render to handle partials
    def @view_context.render(options = {}, locals = {}, &block)
      if options.is_a?(Hash) && options[:partial]
        partial_name = options[:partial]
        locals_hash = options[:locals] || locals
        flash = locals_hash[:flash] || @flash || {}

        if partial_name == 'turbo_toastifier/flash_container'
          max_messages = locals_hash[:max_messages]
          data_attrs = { controller: 'turbo-toastifier-flash-scroll' }
          data_attrs[:'turbo-toastifier-flash-scroll-max-messages-value'] = max_messages unless max_messages.nil?
          turbo_frame_tag(:flash, class: 'flash', refresh: :morph, data: data_attrs) do
            render(partial: 'flash_message', locals: { flash: flash })
          end
        elsif partial_name == 'flash_message'
          flash = locals_hash[:flash] || @flash || {}
          flash.map do |type, messages|
            Array.wrap(messages).map do |message|
              next if message.blank?

              content_tag(:div, message, class: "flash__message --#{type}",
                                         data: { controller: 'turbo-toastifier-flash-removal',
                                                 action: 'animationend->turbo-toastifier-flash-removal#remove' })
            end
          end.flatten.compact.join.html_safe

        else
          "<div>rendered #{partial_name}</div>".html_safe
        end
      elsif block_given?
        capture(&block)
      else
        "<div>rendered</div>".html_safe
      end
    end
  end
end
