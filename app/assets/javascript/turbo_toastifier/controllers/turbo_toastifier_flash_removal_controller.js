import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="turbo-toastifier-flash-removal"
export default class extends Controller {
  static values = {
    index: Number
  }

  connect() {
    // Start animation immediately for the first message, queue others
    // Use requestAnimationFrame + setTimeout to ensure DOM is ready and all controllers connected
    requestAnimationFrame(() => {
      setTimeout(() => {
        // Always try to start - the method will check if it should
        const shouldStart = this.shouldStartAnimation()
        if (shouldStart) {
          this.startAnimation()
        } else {
          // Wait for previous messages to be removed
          this.waitForPreviousMessages()
        }
      }, 100)
    })
  }

  disconnect() {
    // Clean up intervals and timeouts
    if (this.checkInterval) {
      clearInterval(this.checkInterval)
    }
    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
    }
    // When this message is removed, trigger next message to start
    this.triggerNextMessage()
  }

  shouldStartAnimation() {
    try {
      // Find the flash container (could be turbo-frame or direct parent)
      let container = this.element.closest('.flash')

      // If not found, try parent element (might be inside turbo-frame)
      if (!container) {
        container = this.element.parentElement
        // Walk up to find .flash container
        while (container && !container.classList.contains('flash')) {
          container = container.parentElement
          if (!container || container === document.body) break
        }
      }

      // If still no container found, start anyway (safety fallback)
      if (!container) {
        return true
      }

      // Get all messages in the container (excluding ones being removed)
      const messages = Array.from(container.querySelectorAll('.flash__message:not(.removing)'))
      const currentIndex = messages.indexOf(this.element)

      // If index is -1, something went wrong, start anyway
      if (currentIndex === -1) {
        return true
      }

      // If this is the first message (index 0), start immediately
      if (currentIndex === 0) {
        return true
      }

      // Otherwise, check if all previous messages are already animating
      const previousMessages = messages.slice(0, currentIndex)
      if (previousMessages.length === 0) {
        return true
      }

      // Check if all previous messages are animating
      const allPreviousAnimating = previousMessages.every(msg => {
        return msg.classList.contains('animating')
      })

      return allPreviousAnimating
    } catch (e) {
      // If anything goes wrong, start the animation anyway (fail-safe)
      return true
    }
  }

  waitForPreviousMessages() {
    // Check periodically if we can start
    this.checkInterval = setInterval(() => {
      if (this.shouldStartAnimation()) {
        clearInterval(this.checkInterval)
        this.startAnimation()
      }
    }, 100)
  }

  startAnimation() {
    // Only start if not already animating
    if (this.element.classList.contains('animating')) {
      return // Already animating
    }

    // Add the animating class to trigger CSS animation
    this.element.classList.add('animating')

    // Force a reflow to ensure the animation starts immediately
    // Accessing offsetHeight forces browser to recalculate layout
    const height = this.element.offsetHeight

    // Fallback: remove after animation duration (4s) + buffer in case animationend doesn't fire
    this.removalTimeout = setTimeout(() => {
      if (this.element && !this.element.classList.contains('removing')) {
        this.remove()
      }
    }, 4100) // 4s animation + 100ms buffer
  }

  triggerNextMessage() {
    // Find the next message and trigger it to start
    const container = this.element.closest('.flash') || this.element.parentElement
    if (!container) return

    const messages = Array.from(container.querySelectorAll('.flash__message:not(.removing)'))
    const currentIndex = messages.indexOf(this.element)
    const nextMessage = messages[currentIndex + 1]

    if (nextMessage) {
      // Try to get the controller for the next message
      try {
        const controller = this.application.getControllerForElementAndIdentifier(
          nextMessage,
          'turbo-toastifier-flash-removal'
        )
        if (controller && !controller.element.classList.contains('animating')) {
          // Check if it should start now
          if (controller.shouldStartAnimation()) {
            controller.startAnimation()
          }
        }
      } catch (e) {
        // If controller not found, the next message will check on its own via waitForPreviousMessages
        // This is fine - the periodic check will catch it
      }
    }
  }

  pause(event) {
    // Only pause if animation is running
    if (this.element.classList.contains('animating')) {
      // Use both inline style and class for maximum compatibility
      this.element.style.setProperty('animation-play-state', 'paused', 'important')
      this.element.classList.add('paused')
    }
  }

  resume(event) {
    // Only resume if animation was running
    if (this.element.classList.contains('animating')) {
      // Use both inline style and class for maximum compatibility
      this.element.style.setProperty('animation-play-state', 'running', 'important')
      this.element.classList.remove('paused')
    }
  }

  remove(event) {
    // Clear the fallback timeout if it exists
    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
      this.removalTimeout = null
    }

    // Remove the element when animation ends
    this.element.classList.add('removing')
    // Small delay to ensure animation completes visually
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.remove()
      }
    }, 100)
  }
}
