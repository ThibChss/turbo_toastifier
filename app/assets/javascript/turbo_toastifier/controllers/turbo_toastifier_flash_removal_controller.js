import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="turbo-toastifier-flash-removal"
export default class extends Controller {
  connect() {
  }

  remove() {
    this.element.remove()
  }
}
