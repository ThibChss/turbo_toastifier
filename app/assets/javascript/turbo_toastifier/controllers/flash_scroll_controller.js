import { Controller as BaseController } from '@hotwired/stimulus'

export default class FlashScrollController extends BaseController {
  static values = {
    maxMessages: { type: Number, default: 0 }
  }

  connect() {
    this.#handleScroll()
    this.#setEventListeners('add')
    this.enforceMaxMessages()
    this.#enforceAfterDelay()
  }

  disconnect() {
    this.#setEventListeners('remove')
  }

  // ===== Public methods =====

  enforceMaxMessages() {
    this.maxMessagesValue = parseInt(this.maxMessagesValue, 10)

    if (!this.#hasLimit()) {
      this.#setHiddenMessages()

      this.hiddenMessages.forEach(message => {
        message.classList.remove('hidden')
        this.#setRemovalController(message)

        if (this.removalController && !this.#isAnimating()) {
          this.removalController.startAnimation()
        }
      })

      return
    }

    this.#setAllMessages()

    this.allMessages.forEach((message, index) => {
      this.#setRemovalController(message)

      if (index >= this.maxMessagesValue) {
        if (!this.#isHidden(message)) {
          message.classList.add('hidden')

          if (this.removalController) {
            if (this.removalController.removalTimeout) {
              clearTimeout(this.removalController.removalTimeout)
              this.removalController.removalTimeout = null
            }

            if (this.#isAnimating()) {
              this.removalController.element.classList.remove('animating')
            }
          }
        }
      } else {
        if (this.#isHidden(message)) {
          message.classList.remove('hidden')

          setTimeout(() => {
            this.#setRemovalController(message)

            if (this.removalController) {
              if (this.removalController.removalTimeout) {
                clearTimeout(this.removalController.removalTimeout)
                this.removalController.removalTimeout = null
              }

              if (this.removalController.checkInterval) {
                clearInterval(this.removalController.checkInterval)
                this.removalController.checkInterval = null
              }

              this.removalController.remainingTime = this.removalController.displayTime
              this.removalController.animationStartTime = null

              if (this.removalController.isAnimating()) {
                this.removalController.element.classList.remove('animating')
              }

              void this.removalController.element.offsetHeight

              this.removalController.startAnimation()
            }
          }, 10)
        }
      }
    })
  }

  showNextMessage() {
    this.enforceMaxMessages()
  }

  // ===== Private methods =====

  #handleScroll() {
    if (window.scrollY > 100) {
      this.element.classList.add('scrolled')
    } else {
      this.element.classList.remove('scrolled')
    }
  }

  #setEventListeners(type) {
    window[`${type}EventListener`]('scroll', this.#handleScroll.bind(this))
  }


  #setHiddenMessages() {
    this.hiddenMessages = Array.from(this.element.querySelectorAll('.flash__message.hidden'))
  }

  #setAllMessages() {
    this.allMessages = Array.from(this.element.querySelectorAll('.flash__message:not(.removing)'))
  }

  #hasLimit() {
    return this.maxMessagesValue > 0
  }

  #setRemovalController(element = this.element) {
    this.removalController =  this.application?.getControllerForElementAndIdentifier(
      element,
      'turbo-toastifier-flash-removal'
    )
  }

  #isAnimating() {
    return this.removalController?.isAnimating() || false
  }

  #isHidden(element = this.element) {
    return element.classList.contains('hidden')
  }

  #enforceAfterDelay() {
    requestAnimationFrame(() => {
      this.enforceMaxMessages()

      setTimeout(() => {
        this.enforceMaxMessages()
      }, 200)

      setTimeout(() => {
        this.enforceMaxMessages()
      }, 500)
    })
  }
}
