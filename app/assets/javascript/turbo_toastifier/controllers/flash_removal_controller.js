import { Controller as BaseController } from '@hotwired/stimulus'

export default class FlashRemovalController extends BaseController {
  static values = {
    displayTime: { type: Number, default: 4 }
  }

  slideInDuration = 400
  displayTimeInMilliseconds = this.displayTimeValue * 1000
  displayTime = this.slideInDuration + this.displayTimeInMilliseconds

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

  // ===== Private methods =====

  #hideOrShow() {
    requestAnimationFrame(() => {
      setTimeout(() => {
        this.scrollController.enforceMaxMessages()

        if (this.#isVisible()) {
          this.#startAnimation()
        }
      }, 100)
    })
  }

  #setContainer() {
    this.container = this.element.closest('#flash')
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

  #setRemovalController(element) {
    this.removalController = this.application?.getControllerForElementAndIdentifier(
      element,
      'turbo-toastifier-flash-removal'
    )
  }

  #setCurrentIndex() {
    this.currentIndex = this.allMessages.indexOf(this.element)
  }

  #setAnimationStartTime() {
    this.animationStartTime = Date.now()
  }

  #setRemovalTimeout(duration = this.remainingTime) {
    const validDuration = (this.#isValidDuration(duration) && duration > 0)
      ? duration
      : Math.max(100, this.displayTime * 0.1)

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

    this.#setAnimationStartTime()

    this.remainingTime = this.displayTime
    this.element.classList.add('animating')

    void this.element.offsetHeight

    this.#setRemovalTimeout(this.displayTime)
  }

  #startRemoval() {
    if (this.#isRemoving()) { return }

    if (!this.#shouldStartRemoval()) {
      this.#waitForRemovalQueue()

      return
    }

    this.remove()
  }

  #triggerNextRemoval() {
    if (!this.container) { return }

    this.#setRequiredValues()
    this.#setAllMessages('')
    this.scrollController.showNextMessage()

    const nextMessage = this.allMessages[this.currentIndex + 1]
    if (nextMessage && this.#isVisible(nextMessage) && !this.#isRemoving(nextMessage)) {
      this.#setRemovalController(nextMessage)

      if (this.removalController.checkInterval) {
        clearInterval(this.removalController.checkInterval)
        this.removalController.checkInterval = null
      }

      this.removalController.startRemoval()
    }
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
}
