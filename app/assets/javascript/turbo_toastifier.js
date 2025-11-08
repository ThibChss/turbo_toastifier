// Import controllers from separate files
// Note: For importmap to work with separate files, you must pin each file in config/importmap.rb:
//   pin 'turbo_toastifier/controllers/flash_removal_controller', to: 'turbo_toastifier/controllers/flash_removal_controller.js'
//   pin 'turbo_toastifier/controllers/flash_scroll_controller', to: 'turbo_toastifier/controllers/flash_scroll_controller.js'
// For bundlers (esbuild, webpack, etc.), relative imports work automatically

import FlashRemovalController from 'turbo_toastifier/controllers/flash_removal_controller'
import FlashScrollController from 'turbo_toastifier/controllers/flash_scroll_controller'

// Register controllers with Stimulus application
// With importmap, the Stimulus application is typically available as window.application
function registerControllers() {
  let application = null

  if (typeof window !== 'undefined' && window.application) {
    application = window.application
  }

  if (!application && typeof window !== 'undefined' && window.Stimulus) {
    application = window.Stimulus
  }

  if (application && typeof application.register === 'function') {
    application.register('turbo-toastifier-flash-removal', FlashRemovalController)
    application.register('turbo-toastifier-flash-scroll', FlashScrollController)

    return true
  }

  return false
}

// Try to register immediately
let registered = registerControllers()

// If not registered, try again after Stimulus loads
if (!registered && typeof window !== 'undefined') {
  const attempts = [100, 300, 500, 1000, 2000]
  attempts.forEach(delay => {
    setTimeout(() => {
      if (!registered) {
        registered = registerControllers()
      }
    }, delay)
  })

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      if (!registered) {
        registered = registerControllers()
      }
    })
  }
}
