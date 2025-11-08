import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals'
import FlashRemovalController from '../../../app/assets/javascript/turbo_toastifier/controllers/flash_removal_controller.js'

describe('FlashRemovalController', () => {
  let controller
  let element
  let container
  let mockApplication

  beforeEach(() => {
    // Create DOM structure
    container = document.createElement('div')
    container.id = 'flash'
    container.setAttribute('data-controller', 'turbo-toastifier-flash-scroll')
    container.setAttribute('data-turbo-toastifier-flash-scroll-max-messages-value', '0')
    document.body.appendChild(container)

    element = document.createElement('div')
    element.className = 'flash__message'
    element.setAttribute('data-controller', 'turbo-toastifier-flash-removal')
    element.setAttribute('data-turbo-toastifier-flash-removal-display-time-value', '4')
    container.appendChild(element)

    // Mock Stimulus application
    mockApplication = {
      getControllerForElementAndIdentifier: jest.fn(() => null)
    }

    // Create controller instance
    controller = new FlashRemovalController(element, 'turbo-toastifier-flash-removal')
    controller.application = mockApplication
    // Set up controller values
    Object.defineProperty(controller, 'displayTimeValue', { value: 4, writable: true, configurable: true })
    controller.displayTime = 4400 // 400ms slide-in + 4000ms display
    // Set up container (normally done in connect)
    controller.container = container
  })

  afterEach(() => {
    if (controller) {
      controller.disconnect()
    }
    document.body.innerHTML = ''
    jest.clearAllTimers()
  })

  describe('#pause', () => {
    it('adds paused class to element', () => {
      controller.pause()
      expect(element.classList.contains('paused')).toBe(true)
    })

    it('does not pause if already paused', () => {
      element.classList.add('paused')
      controller.pause()
      // Should still only have one 'paused' class
      expect(element.classList.contains('paused')).toBe(true)
    })

    it('pauses even if element is removing and stops removal animation', () => {
      element.classList.add('removing')
      controller.remainingTime = 1000 // Set some remaining time
      controller.pause()
      // Should pause and remove the removing class
      expect(element.classList.contains('paused')).toBe(true)
      expect(element.classList.contains('removing')).toBe(false)
      // Should reset remaining time to minimum
      expect(controller.remainingTime).toBeGreaterThanOrEqual(100)
    })

    it('calculates remaining time when animationStartTime is set', () => {
      controller.animationStartTime = Date.now() - 1000 // 1 second ago
      controller.remainingTime = 4400
      controller.removalTimeout = setTimeout(() => {}, 1000)

      controller.pause()

      expect(controller.remainingTime).toBe(3400) // 4400 - 1000
      expect(controller.removalTimeout).toBe(null)
    })

    it('sets remainingTime to displayTime if animationStartTime is not set', () => {
      controller.pause()
      expect(controller.remainingTime).toBe(4400)
    })

    it('clears removalTimeout when pausing', () => {
      controller.removalTimeout = setTimeout(() => {}, 1000)
      controller.pause()
      expect(controller.removalTimeout).toBe(null)
    })
  })

  describe('#resume', () => {
    beforeEach(() => {
      element.classList.add('paused')
      controller.remainingTime = 2000
    })

    it('removes paused class from element', () => {
      controller.resume()
      expect(element.classList.contains('paused')).toBe(false)
    })

    it('does not resume if not paused', () => {
      element.classList.remove('paused')
      controller.resume()
      expect(controller.animationStartTime).toBeUndefined()
    })

    it('removes removing class and resumes if element is removing', () => {
      element.classList.add('paused')
      element.classList.add('removing')
      controller.resume()
      // Should remove both removing and paused classes, and resume
      expect(element.classList.contains('removing')).toBe(false)
      expect(element.classList.contains('paused')).toBe(false)
      expect(controller.animationStartTime).toBeDefined()
    })

    it('sets animationStartTime when resuming', () => {
      controller.resume()
      expect(controller.animationStartTime).toBeDefined()
    })

    it('creates removalTimeout when resuming', () => {
      controller.resume()
      expect(controller.removalTimeout).toBeDefined()
    })

    it('resets remainingTime to minimum if it is zero or negative', () => {
      controller.remainingTime = 0
      controller.resume()
      expect(controller.remainingTime).toBeGreaterThan(0)
    })

    it('uses remainingTime for timeout duration', () => {
      controller.remainingTime = 2000
      controller.resume()
      // The timeout should be set with the remaining time
      expect(controller.removalTimeout).toBeDefined()
    })
  })

  describe('#remove', () => {
    it('adds removing class to element', () => {
      controller.remove()
      expect(element.classList.contains('removing')).toBe(true)
    })

    it('clears removalTimeout when removing', () => {
      controller.removalTimeout = setTimeout(() => {}, 1000)
      controller.remove()
      expect(controller.removalTimeout).toBe(null)
    })

    it('does not remove element if animationend event is from slide-in', () => {
      const removeSpy = jest.spyOn(element, 'remove')
      const event = { type: 'animationend' }

      controller.remove(event)

      expect(element.classList.contains('removing')).toBe(false)
      expect(removeSpy).not.toHaveBeenCalled()
    })

    it('removes element if animationend event is from fade-out', () => {
      element.classList.add('removing')
      const removeSpy = jest.spyOn(element, 'remove')
      // Mock scrollController to avoid errors
      controller.scrollController = { showNextMessage: jest.fn() }
      const event = { type: 'animationend' }

      controller.remove(event)

      expect(removeSpy).toHaveBeenCalled()
    })
  })

  describe('#isAnimating', () => {
    it('returns true when element has animating class', () => {
      element.classList.add('animating')
      expect(controller.isAnimating()).toBe(true)
    })

    it('returns false when element does not have animating class', () => {
      expect(controller.isAnimating()).toBe(false)
    })
  })

  describe('timing and intervals', () => {
    it('clears checkInterval on disconnect', () => {
      const clearIntervalSpy = jest.spyOn(global, 'clearInterval')
      controller.checkInterval = setInterval(() => {}, 50)
      const intervalId = controller.checkInterval
      controller.disconnect()
      // Verify that clearInterval was called with the interval ID
      expect(clearIntervalSpy).toHaveBeenCalledWith(intervalId)
      clearIntervalSpy.mockRestore()
    })

    it('clears removalTimeout on disconnect', () => {
      const clearTimeoutSpy = jest.spyOn(global, 'clearTimeout')
      controller.removalTimeout = setTimeout(() => {}, 1000)
      const timeoutId = controller.removalTimeout
      controller.disconnect()
      // Verify that clearTimeout was called with the timeout ID
      expect(clearTimeoutSpy).toHaveBeenCalledWith(timeoutId)
      clearTimeoutSpy.mockRestore()
    })
  })
})
