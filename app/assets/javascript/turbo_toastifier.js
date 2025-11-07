// Flash Removal Controller (bundled inline for importmap compatibility)
import { Controller as BaseController } from '@hotwired/stimulus'

class FlashRemovalController extends BaseController {
  static values = {
    index: Number
  }

  connect() {
    // All messages should animate in immediately when added
    // No queue for appearing - they all appear and stack
    requestAnimationFrame(() => {
      setTimeout(() => {
        this.startAnimation()
      }, 100)
    })
  }

  disconnect() {
    if (this.checkInterval) {
      clearInterval(this.checkInterval)
    }
    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
    }
  }

  shouldStartRemoval() {
    // Check if this message should start its removal animation
    // Removal should be queued: only one message removes at a time
    // Also wait if any message is paused (hovered)
    try {
      let container = this.element.closest('.flash')
      if (!container) {
        container = this.element.parentElement
        while (container && !container.classList.contains('flash')) {
          container = container.parentElement
          if (!container || container === document.body) break
        }
      }
      if (!container) {
        return true
      }
      // Check if any other message is currently being removed
      const removingMessages = Array.from(container.querySelectorAll('.flash__message.removing'))
      if (removingMessages.length > 0) {
        return false
      }
      // Check if any message before this one is paused (hovered)
      // If so, wait for it to finish removing before starting this one
      const allMessages = Array.from(container.querySelectorAll('.flash__message:not(.removing)'))
      const currentIndex = allMessages.indexOf(this.element)
      if (currentIndex > 0) {
        const previousMessages = allMessages.slice(0, currentIndex)
        const hasPausedPrevious = previousMessages.some(msg =>
          msg.classList.contains('paused')
        )
        if (hasPausedPrevious) {
          return false
        }
      }
      // Only start removal if no other messages are being removed and no previous messages are paused
      return true
    } catch (e) {
      return true
    }
  }

  waitForRemovalQueue() {
    // Check immediately first
    if (this.shouldStartRemoval()) {
      this.startRemoval()
      return
    }
    // Then check periodically until it's this message's turn to remove
    this.checkInterval = setInterval(() => {
      if (this.shouldStartRemoval()) {
        clearInterval(this.checkInterval)
        this.checkInterval = null
        this.startRemoval()
      }
    }, 50)
  }

  startAnimation() {
    if (this.element.classList.contains('animating')) {
      return
    }
    // Store animation start time for pause/resume calculations
    this.animationStartTime = Date.now()
    // Add the animating class - the CSS animation will handle the transition smoothly
    // The 'both' keyword ensures the 0% keyframe is applied before animation starts
    this.element.classList.add('animating')
    // Force a reflow to ensure animation starts immediately
    void this.element.offsetHeight
    // Message stays visible for 4 seconds AFTER the slide-in animation completes
    // Slide-in animation is 400ms, so total timeout = 400ms (animation) + 4000ms (visible time)
    this.remainingTime = 4400
    // Start the removal timeout - message will start removing 4 seconds after animation completes
    this.removalTimeout = setTimeout(() => {
      if (this.element && !this.element.classList.contains('removing') && !this.element.classList.contains('paused')) {
        this.startRemoval()
      }
    }, this.remainingTime)
  }

  startRemoval() {
    // Start the removal process - this is queued so only one removes at a time
    if (this.element.classList.contains('removing')) {
      return
    }
    // Check if we should start removal (queue system)
    if (!this.shouldStartRemoval()) {
      // Wait for other messages to finish removing
      this.waitForRemovalQueue()
      return
    }
    // Start removal
    this.remove()
  }

  triggerNextRemoval() {
    // When this message finishes removing, trigger the next one to start removing
    const container = this.element.closest('.flash') || this.element.parentElement
    if (!container) return
    // Get all messages (including the one being removed, to find position)
    const allMessages = Array.from(container.querySelectorAll('.flash__message'))
    const currentIndex = allMessages.indexOf(this.element)

    // Find the next message in the queue (that's not being removed)
    const nextMessage = allMessages[currentIndex + 1]
    if (nextMessage && !nextMessage.classList.contains('removing')) {
      try {
        const controller = this.application.getControllerForElementAndIdentifier(
          nextMessage,
          'turbo-toastifier-flash-removal'
        )
        if (controller) {
          // Clear any existing wait interval since we're triggering it now
          if (controller.checkInterval) {
            clearInterval(controller.checkInterval)
            controller.checkInterval = null
          }
          // Start the removal process for the next message
          controller.startRemoval()
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  pause(event) {
    // Pause the removal countdown when hovering
    if (!this.element.classList.contains('paused') && !this.element.classList.contains('removing')) {
      // Calculate elapsed time since animation started or last resume
      if (this.animationStartTime) {
        const elapsed = Date.now() - this.animationStartTime
        this.remainingTime = Math.max(0, this.remainingTime - elapsed)
      }
      // Clear the removal timeout
      if (this.removalTimeout) {
        clearTimeout(this.removalTimeout)
        this.removalTimeout = null
      }
      // Mark as paused - this prevents other messages from removing
      this.element.classList.add('paused')
    }
  }

  resume(event) {
    // Resume the removal countdown when mouse leaves
    if (this.element.classList.contains('paused') && !this.element.classList.contains('removing')) {
      // Remove paused class - this allows other messages to start removing
      this.element.classList.remove('paused')
      // Trigger waiting messages to check if they can start removing now
      this.triggerWaitingMessages()
      // Restart the removal timeout with remaining time
      if (this.remainingTime > 0) {
        this.animationStartTime = Date.now()
        this.removalTimeout = setTimeout(() => {
          if (this.element && !this.element.classList.contains('removing') && !this.element.classList.contains('paused')) {
            this.startRemoval()
          }
        }, this.remainingTime)
      } else {
        // If no time remaining, start removal immediately
        this.startRemoval()
      }
    }
  }

  triggerWaitingMessages() {
    // When a message resumes, check if any waiting messages can now start removing
    const container = this.element.closest('.flash') || this.element.parentElement
    if (!container) return
    const allMessages = Array.from(container.querySelectorAll('.flash__message:not(.removing)'))
    const currentIndex = allMessages.indexOf(this.element)
    // Check messages after this one that might be waiting
    const nextMessages = allMessages.slice(currentIndex + 1)
    nextMessages.forEach(msg => {
      if (msg.classList.contains('paused')) {
        return // Skip paused messages
      }
      try {
        const controller = this.application.getControllerForElementAndIdentifier(
          msg,
          'turbo-toastifier-flash-removal'
        )
        if (controller && controller.checkInterval) {
          // Message is waiting, trigger a check
          if (controller.shouldStartRemoval()) {
            clearInterval(controller.checkInterval)
            controller.checkInterval = null
            controller.startRemoval()
          }
        }
      } catch (e) {
        // Ignore
      }
    })
  }

  remove(event) {
    // If called from animationend event, check if it's the removal animation
    // The slide-in animation also fires animationend, but we should ignore it
    if (event && event.type === 'animationend') {
      // Only proceed if element is already marked as removing (fade-out animation ended)
      // If not removing yet, this is the slide-in animation ending - ignore it
      if (!this.element.classList.contains('removing')) {
        return
      }
      // This is the fade-out animation ending, proceed with DOM removal
      if (this.element && this.element.parentNode) {
        this.element.remove()
        // Trigger the next message to start its removal
        this.triggerNextRemoval()
      }
      return
    }

    // Called from timeout or programmatically - start the removal process
    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
      this.removalTimeout = null
    }
    // Mark as removing - this triggers the removal animation
    this.element.classList.add('removing')
    // The fade-out animation will complete and trigger animationend,
    // which will handle the actual DOM removal
  }
}

// Flash Scroll Controller (bundled inline for importmap compatibility)
class FlashScrollController extends BaseController {
  connect() {
    this.handleScroll()
    window.addEventListener('scroll', this.handleScroll.bind(this))
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll.bind(this))
  }

  handleScroll() {
    if (window.scrollY > 100) {
      this.element.classList.add('scrolled')
    } else {
      this.element.classList.remove('scrolled')
    }
  }
}

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
