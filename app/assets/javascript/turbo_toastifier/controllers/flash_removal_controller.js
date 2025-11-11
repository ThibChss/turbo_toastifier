import { Controller as BaseController } from '@hotwired/stimulus'

export default class FlashRemovalController extends BaseController {
  static values = {
    displayTime: { type: Number, default: 4 },
    dismissMode: { type: String, default: 'button' }
  }

  slideInDuration = 400
  displayTimeInMilliseconds = this.displayTimeValue * 1000
  displayTime = this.displayTimeValue === 0 ? 0 : this.slideInDuration + this.displayTimeInMilliseconds
  manuallyDismissed = false

  connect() {
    this.#setContainer()
    this.#setRequiredValues()
    this.#setScrollController()
    this.#shouldBeHidden()

    this.#hideOrShow()
  }

  disconnect() {
    if (this.checkInterval) {
      clearInterval(this.checkInterval)
    }

    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
    }
  }

  // ===== Public methods =====

  pause() {
    if (this.#isPaused()) return
    // Don't pause if manually dismissed - it should stay removed
    if (this.manuallyDismissed) return

    // If displayTime is 0, don't pause (message should stay visible until manually dismissed)
    if (this.displayTime === 0) {
      return
    }

    const wasRemoving = this.#isRemoving()

    if (wasRemoving) {
      this.element.classList.remove('removing')
    }

    if (this.animationStartTime && this.#isValidDuration(this.remainingTime)) {
      this.remainingTime = Math.max(
        this.#minimumDuration(),
        this.remainingTime - (Date.now() - this.animationStartTime)
      )
    } else {
      if (wasRemoving) {
        this.remainingTime = this.#minimumDuration()
      } else {
        this.remainingTime = this.displayTime
      }
    }

    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
      this.removalTimeout = null
    }

    this.element.classList.add('paused')
  }

  resume() {
    if (!this.#isPaused()) return
    if (this.manuallyDismissed) return

    if (this.displayTime === 0) {
      this.element.classList.remove('paused')
      if (this.removalTimeout) {
        clearTimeout(this.removalTimeout)
        this.removalTimeout = null
      }
      this.remainingTime = 0
      this.#triggerWaitingMessages()
      return
    }

    if (this.#isRemoving()) {
      this.element.classList.remove('removing')
    }

    this.element.classList.remove('paused')

    if (!this.#isValidDuration(this.remainingTime) || this.remainingTime <= 0) {
      this.remainingTime = this.#minimumDuration()
    } else {
      this.remainingTime = Math.max(this.#minimumDuration(), this.remainingTime)
    }

    this.#setAnimationStartTime()

    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
      this.removalTimeout = null
    }

    this.#setRemovalTimeout(this.remainingTime)
    this.#triggerWaitingMessages()
  }

  dismiss() {
    this.manuallyDismissed = true

    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
      this.removalTimeout = null
    }

    if (this.checkInterval) {
      clearInterval(this.checkInterval)
      this.checkInterval = null
    }

    if (this.#isPaused()) {
      this.element.classList.remove('paused')
    }

    this.element.classList.add('removing')
  }

  handleClick(event) {
    if (this.dismissModeValue !== 'click') {
      return
    }

    if (event.target.closest('.flash__message-close')) {
      return
    }

    if (event.target.closest('a, button')) {
      return
    }

    // Dismiss the message
    this.dismiss()
  }

  remove(event) {
    if (event && event.type === 'animationend') {
      if (!this.#isRemoving()) {
        return
      }

      this.element.remove()
      this.#triggerNextRemoval()

      return
    }

    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
      this.removalTimeout = null
    }

    this.element.classList.add('removing')
  }

  isAnimating(element = this.element) {
    return element.classList.contains('animating')
  }

  shouldStartRemoval() {
    return this.#shouldStartRemoval()
  }

  startRemoval() {
    this.#startRemoval()
  }

  startAnimation() {
    this.#startAnimation()
  }

  setRemovalTimeout(duration = this.remainingTime) {
    this.#setRemovalTimeout(duration)
  }

  waitForRemovalQueue() {
    this.#waitForRemovalQueue()
  }

  setRequiredValues() {
    this.#setRequiredValues()
  }

  // ===== Private methods =====

  #hideOrShow() {
    if (this.scrollController) {
      this.scrollController.enforceMaxMessages()
    }

    requestAnimationFrame(() => {
      if (this.scrollController) {
        this.scrollController.enforceMaxMessages()
      }

      setTimeout(() => {
        if (this.scrollController) {
          this.scrollController.enforceMaxMessages()
        }

        if (this.#isVisible()) {
          this.#startAnimation()
        }
      }, 100)

      setTimeout(() => {
        if (this.scrollController) {
          this.scrollController.enforceMaxMessages()
        }
      }, 300)
    })
  }

  #setContainer() {
    this.container = this.element.closest('.flash')

    if (!this.container) {
      this.container = this.element.closest('#flash')
    }
  }

  #setMaxMessagesValue() {
    this.maxMessagesValue = parseInt(this.container.dataset.turboToastifierFlashScrollMaxMessagesValue, 10)
  }

  #setAllMessages(className = ':not(.removing)') {
    this.allMessages = Array.from(this.container.querySelectorAll(`.flash__message${className}`))
  }

  #setRemovingMessages() {
    this.removingMessages = Array.from(this.container.querySelectorAll('.flash__message.removing'))
  }

  #setScrollController() {
    this.scrollController = this.application?.getControllerForElementAndIdentifier(
      this.container,
      'turbo-toastifier-flash-scroll'
    )
  }

  #setRemovalController(element, variable = false) {
    const controller = this.application?.getControllerForElementAndIdentifier(
      element,
      'turbo-toastifier-flash-removal'
    )

    if (variable) {
      return controller
    }

    this.removalController = controller
  }

  #setCurrentIndex() {
    this.currentIndex = this.allMessages.indexOf(this.element)
  }

  #setAnimationStartTime() {
    this.animationStartTime = Date.now()
  }

  #setRemovalTimeout(duration = this.remainingTime) {
    if (this.displayTime === 0) {
      return
    }

    let validDuration = duration

    if (!this.#isValidDuration(duration) || duration <= 0) {
      validDuration = this.displayTime
    }

    validDuration = Math.max(100, validDuration)

    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
      this.removalTimeout = null
    }

    this.removalTimeout = setTimeout(() => {
      if (!this.#isRemoving() && !this.#isPaused()) {
        this.#startRemoval()
      }
    }, validDuration)
  }

  #setCheckInterval() {
    this.checkInterval = setInterval(() => {
      if (this.#shouldStartRemoval()) {
        clearInterval(this.checkInterval)

        this.checkInterval = null
        this.#startRemoval()
      }
    }, 50)
  }

  #shouldBeHidden() {
    this.#setMaxMessagesValue()

    if (this.maxMessagesValue > 0) {
      this.#setRequiredValues()

      if (this.currentIndex >= this.maxMessagesValue) {
        this.element.classList.add('hidden')

        return
      }
    }
  }

  #isVisible(element = this.element) {
    return !element.classList.contains('hidden')
  }

  #isPaused(element = this.element) {
    return element.classList.contains('paused')
  }

  #isRemoving(element = this.element) {
    return element.classList.contains('removing')
  }

  #shouldStartRemoval() {
    this.#setRequiredValues()

    if (!this.container) { return true }

    if (this.removingMessages.length > 0) { return false }

    if (this.currentIndex > 0) {
      const previousMessages = this.allMessages.slice(0, this.currentIndex)
      const hasPausedPrevious = previousMessages.some(message => this.#isPaused(message))

      if (hasPausedPrevious) {
        return false
      }
    }

    return true
  }

  #waitForRemovalQueue() {
    if (this.#shouldStartRemoval()) {
      this.#startRemoval()

      return
    }

    this.#setCheckInterval()
  }

  #startAnimation() {
    if (this.isAnimating()) { return }

    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout)
      this.removalTimeout = null
    }

    if (this.checkInterval) {
      clearInterval(this.checkInterval)
      this.checkInterval = null
    }

    this.#setAnimationStartTime()
    this.remainingTime = this.displayTime
    this.element.classList.add('animating')

    void this.element.offsetHeight

    if (this.displayTime > 0) {
      this.#setRemovalTimeout(this.displayTime)
    }
  }

  #startRemoval() {
    if (this.#isRemoving()) { return }

    if (this.displayTime === 0) {
      return
    }

    if (!this.#shouldStartRemoval()) {
      this.#waitForRemovalQueue()

      return
    }

    this.remove()
  }

  #triggerNextRemoval() {
    if (!this.container) { return }

    requestAnimationFrame(() => {
      if (this.scrollController) {
        this.scrollController.showNextMessage()
      }

      setTimeout(() => {
        this.#setAllMessages()

        const visibleMessages = this.allMessages.filter(message => {
          return this.#isVisible(message) && !this.#isRemoving(message) && !this.#isPaused(message)
        })

        const firstVisibleMessage = visibleMessages[0]
        if (firstVisibleMessage) {
          const removalController = this.#setRemovalController(firstVisibleMessage, true)

          if (removalController) {
            const hadCheckInterval = !!removalController.checkInterval
            const isAnimating = removalController.isAnimating()
            const hasTimeout = !!removalController.removalTimeout

            if (removalController.checkInterval) {
              clearInterval(removalController.checkInterval)

              removalController.checkInterval = null
            }

            this.#ensureRequiredValues(removalController)

            const shouldStart = removalController.shouldStartRemoval()

            if (hadCheckInterval && shouldStart) {
              removalController.startRemoval()

              return
            }

            if (isAnimating && !hasTimeout && shouldStart) {
              removalController.startRemoval()

              return
            }

            if (hadCheckInterval && !shouldStart) {
              setTimeout(() => {
                this.#ensureRequiredValues(removalController)

                if (removalController.shouldStartRemoval()) {
                  removalController.startRemoval()
                } else {
                  setTimeout(() => {
                    removalController.setRequiredValues()

                    if (removalController.shouldStartRemoval()) {
                      removalController.startRemoval()
                    } else {
                      removalController.waitForRemovalQueue()
                    }
                  }, 50)
                }
              }, 10)

              return
            }

            if (isAnimating && !hasTimeout && !shouldStart) {
              setTimeout(() => {
                removalController.setRequiredValues()

                if (removalController.shouldStartRemoval()) {
                  removalController.startRemoval()
                } else {
                  removalController.waitForRemovalQueue()
                }
              }, 10)

              return
            }

            if (!hasTimeout) {
              if (isAnimating) {
                removalController.remainingTime = removalController.displayTime
                removalController.setRemovalTimeout(removalController.displayTime)
              } else {
                removalController.remainingTime = removalController.displayTime
                removalController.startAnimation()
              }
            }
          }
        }
      }, 50)
    })
  }

  #triggerWaitingMessages() {
    this.#setRequiredValues()

    const nextMessages = this.allMessages.slice(this.currentIndex + 1)
    nextMessages.forEach(message => {
      if (this.#isPaused(message)) { return }
      this.#setRemovalController(message)
      if (this.removalController.checkInterval && this.removalController.shouldStartRemoval()) {
        clearInterval(this.removalController.checkInterval)

        this.removalController.checkInterval = null
        this.removalController.startRemoval()
      }
    })
  }

  #setRequiredValues() {
    this.#setAllMessages()
    this.#setRemovingMessages()
    this.#setCurrentIndex()
  }

  #isValidDuration(duration) {
    return duration !== undefined && !isNaN(duration)
  }

  #minimumDuration() {
    return Math.max(100, this.displayTime * 0.1)
  }

  #ensureRequiredValues(controller = this.removalController) {
    controller.setRequiredValues()
    controller.setRequiredValues()
  }
}
