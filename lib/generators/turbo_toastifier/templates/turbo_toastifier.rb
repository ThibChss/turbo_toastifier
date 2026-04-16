# frozen_string_literal: true

# TurboToastifier Configuration
#
# This file configures the default behavior for TurboToastifier flash messages.
# Run `rails turbo_toastifier:install` to regenerate this file.
#
# After modifying this file, restart your Rails server for changes to take effect.

TurboToastifier.configure do |config|
  # Maximum number of messages to display at once
  #
  # Set to 0 for unlimited messages (default behavior).
  # When set to a positive integer, only that many messages will be visible at once.
  # Additional messages will be queued and automatically appear when visible messages are removed.
  #
  # Example:
  #   config.limit = 5  # Only show 5 messages at a time
  #   config.limit = 0  # Show all messages (unlimited)
  # config.limit = 0

  # Display duration in seconds, or a hash of flash_type => duration
  #
  # When set to an integer, all messages will use that duration.
  # When set to a hash, each flash type can have its own duration.
  #
  # Duration values:
  #   - Positive integer: Message will auto-remove after that many seconds
  #   - 0: Message will never auto-remove (shows close button for manual dismissal)
  #
  # Examples:
  #   # All messages disappear after 4 seconds
  #   config.duration = 4
  #
  #   # Notice messages disappear after 4s, alert messages require manual dismissal
  #   config.duration = { notice: 4, alert: 0 }
  #
  #   # All messages require manual dismissal (close button appears)
  #   config.duration = 0
  #
  #   # Per-flash-type configuration with multiple types
  #   config.duration = {
  #     notice: 4,   # Auto-remove after 4 seconds
  #     alert: 0,    # Manual dismissal required
  #     success: 5,  # Auto-remove after 5 seconds
  #     error: 0     # Manual dismissal required
  #   }
  # config.duration = 4

  # Dismiss mode for flash messages
  #
  # Controls how users can dismiss messages:
  #   - :button (default): Only the close button (✕) can dismiss messages
  #   - :click: Click anywhere on the message to dismiss
  #
  # When set to :click:
  #   - Users can click anywhere on the message to dismiss it
  #   - Clicking on links or buttons inside the message will NOT dismiss it
  #   - The close button is hidden (unless duration is 0)
  #
  # When set to :button:
  #   - Only the close button can dismiss messages
  #   - Close button appears when duration is 0 (manual dismissal required)
  #
  # Examples:
  #   config.dismiss = :button  # Only close button (default)
  #   config.dismiss = :click   # Click anywhere to dismiss
  #
  # config.dismiss = :button

  # View partials for flash markup (optional overrides)
  #
  # Point these at your own partials to control layout and styling (Tailwind classes,
  # custom markup, or a thin ERB wrapper around a Phlex component).
  #
  # Your partial receives the same view context as other templates, including
  # `flash`, plus TurboToastifier helpers: `configuration`, `actions`,
  # `should_show_close_button?` (from TurboToastifier::ViewHelper).
  #
  # When replacing `flash_message_partial`, keep the Stimulus hooks from the default
  # partial unless you reimplement dismissal: data-controller="turbo-toastifier-flash-removal",
  # data-turbo-toastifier-flash-removal-display-time-value, data-turbo-toastifier-flash-removal-dismiss-mode-value,
  # and data-action bound to the `actions` helper on the dismissible root element.
  #
  # config.flash_message_partial = 'turbo_toastifier/flash_message'
  # config.flash_container_partial = 'turbo_toastifier/flash_container'
end
