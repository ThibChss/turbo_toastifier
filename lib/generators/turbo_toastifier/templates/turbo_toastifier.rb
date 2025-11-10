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
  config.limit = 0

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
  config.duration = 4
end
