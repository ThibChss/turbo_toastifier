import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals'
import FlashScrollController from '../../../app/assets/javascript/turbo_toastifier/controllers/flash_scroll_controller.js'

describe('FlashScrollController', () => {
  let controller
  let element
  let mockApplication

  beforeEach(() => {
    // Create DOM structure
    element = document.createElement('div')
    element.id = 'flash'
    element.className = 'flash'
    element.setAttribute('data-controller', 'turbo-toastifier-flash-scroll')
    element.setAttribute('data-turbo-toastifier-flash-scroll-max-messages-value', '0')
    document.body.appendChild(element)

    // Mock Stimulus application
    mockApplication = {
      getControllerForElementAndIdentifier: jest.fn(() => null)
    }

    // Create controller instance
    controller = new FlashScrollController(element, 'turbo-toastifier-flash-scroll')
    controller.application = mockApplication
    // Set up controller values
    Object.defineProperty(controller, 'maxMessagesValue', { value: 0, writable: true, configurable: true })
  })

  afterEach(() => {
    if (controller) {
      controller.disconnect()
    }
    document.body.innerHTML = ''
    jest.clearAllTimers()
  })

  describe('#enforceMaxMessages', () => {
    let mockRemovalController

    beforeEach(() => {
      // Create mock removal controller
      mockRemovalController = {
        element: document.createElement('div'),
        isAnimating: jest.fn(() => false),
        startAnimation: jest.fn(),
        removalTimeout: null
      }
      mockRemovalController.element.className = 'flash__message'
      element.appendChild(mockRemovalController.element)

      // Create multiple messages
      for (let i = 0; i < 4; i++) {
        const message = document.createElement('div')
        message.className = 'flash__message'
        element.appendChild(message)
      }

      // Mock the application to return the removal controller
      mockApplication.getControllerForElementAndIdentifier = jest.fn(() => mockRemovalController)
      controller.removalController = mockRemovalController
    })

    it('shows all messages when maxMessages is 0', () => {
      Object.defineProperty(controller, 'maxMessagesValue', { value: 0, writable: true, configurable: true })
      controller.enforceMaxMessages()

      const messages = element.querySelectorAll('.flash__message')
      messages.forEach(msg => {
        expect(msg.classList.contains('hidden')).toBe(false)
      })
    })

    it('hides messages beyond maxMessages limit', () => {
      Object.defineProperty(controller, 'maxMessagesValue', { value: 3, writable: true, configurable: true })
      controller.enforceMaxMessages()

      const messages = Array.from(element.querySelectorAll('.flash__message:not(.removing)'))
      expect(messages[0].classList.contains('hidden')).toBe(false)
      expect(messages[1].classList.contains('hidden')).toBe(false)
      expect(messages[2].classList.contains('hidden')).toBe(false)
      if (messages[3]) {
        expect(messages[3].classList.contains('hidden')).toBe(true)
      }
    })

    it('shows messages within maxMessages limit', () => {
      // First hide all beyond limit
      Object.defineProperty(controller, 'maxMessagesValue', { value: 2, writable: true, configurable: true })
      controller.enforceMaxMessages()

      // Then increase limit
      Object.defineProperty(controller, 'maxMessagesValue', { value: 4, writable: true, configurable: true })
      controller.enforceMaxMessages()

      const messages = Array.from(element.querySelectorAll('.flash__message:not(.removing)'))
      messages.forEach((msg, index) => {
        if (index < 4) {
          expect(msg.classList.contains('hidden')).toBe(false)
        }
      })
    })
  })

  describe('#showNextMessage', () => {
    beforeEach(() => {
      // Create multiple messages
      for (let i = 0; i < 5; i++) {
        const message = document.createElement('div')
        message.className = 'flash__message'
        if (i >= 3) {
          message.classList.add('hidden')
        }
        element.appendChild(message)
      }
    })

    it('calls enforceMaxMessages', () => {
      const enforceSpy = jest.spyOn(controller, 'enforceMaxMessages')
      controller.showNextMessage()
      expect(enforceSpy).toHaveBeenCalled()
    })
  })

  describe('scroll handling', () => {
    it('adds scrolled class when window scrollY > 100', () => {
      Object.defineProperty(window, 'scrollY', { value: 150, writable: true, configurable: true })
      // handleScroll is private, so we test it via connect which calls it
      controller.connect()
      expect(element.classList.contains('scrolled')).toBe(true)
    })

    it('removes scrolled class when window scrollY <= 100', () => {
      element.classList.add('scrolled')
      Object.defineProperty(window, 'scrollY', { value: 50, writable: true, configurable: true })
      // handleScroll is private, so we test it via connect which calls it
      controller.connect()
      expect(element.classList.contains('scrolled')).toBe(false)
    })
  })

  describe('event listeners', () => {
    it('removes scroll listener on disconnect', () => {
      const removeSpy = jest.spyOn(window, 'removeEventListener')
      controller.disconnect()
      expect(removeSpy).toHaveBeenCalledWith('scroll', expect.any(Function))
    })
  })
})
