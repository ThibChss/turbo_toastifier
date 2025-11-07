import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="turbo-toastifier-flash-scroll"
export default class extends Controller {
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
